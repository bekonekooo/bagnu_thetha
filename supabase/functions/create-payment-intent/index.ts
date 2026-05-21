import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import Stripe from "https://esm.sh/stripe@16.12.0?target=deno";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY");
const supabaseUrl = Deno.env.get("SUPABASE_URL");
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!stripeSecretKey) {
  throw new Error("Missing STRIPE_SECRET_KEY");
}

if (!supabaseUrl) {
  throw new Error("Missing SUPABASE_URL");
}

if (!supabaseServiceRoleKey) {
  throw new Error("Missing SUPABASE_SERVICE_ROLE_KEY");
}

const stripe = new Stripe(stripeSecretKey, {
  apiVersion: "2024-06-20",
});

const supabaseAdmin = createClient(
  supabaseUrl,
  supabaseServiceRoleKey,
);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function parseAmountToMinorUnit(amount: unknown) {
  const parsedAmount = Number(amount);

  if (!Number.isFinite(parsedAmount) || parsedAmount <= 0) {
    throw new Error("Geçersiz ödeme tutarı.");
  }

  return Math.round(parsedAmount * 100);
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  if (req.method !== "POST") {
    return jsonResponse(
      {
        error: "Only POST requests are allowed.",
      },
      405,
    );
  }

  try {
    const authHeader = req.headers.get("Authorization");

    if (!authHeader) {
      return jsonResponse(
        {
          error: "Authorization header is missing.",
        },
        401,
      );
    }

    const token = authHeader.replace("Bearer ", "");

    const {
      data: userData,
      error: userError,
    } = await supabaseAdmin.auth.getUser(token);

    if (userError || !userData.user) {
      return jsonResponse(
        {
          error: "Kullanıcı doğrulanamadı.",
        },
        401,
      );
    }

    const userId = userData.user.id;
    const body = await req.json();

    const teacherId = body.teacherId?.toString();
    const teacherName = body.teacherName?.toString();
    const sessionDate = body.sessionDate?.toString();
    const sessionTime = body.sessionTime?.toString();
    const notes = body.notes?.toString() || null;

    const amount = Number(body.amount);
    const currency = body.currency?.toString().toLowerCase() || "try";

    if (!teacherId || !teacherName || !sessionDate || !sessionTime) {
      return jsonResponse(
        {
          error: "Eksik seans bilgisi.",
        },
        400,
      );
    }

    if (currency !== "try") {
      return jsonResponse(
        {
          error: "Şimdilik sadece TRY ödemesi destekleniyor.",
        },
        400,
      );
    }

    const amountMinor = parseAmountToMinorUnit(amount);

    const {
      data: teacher,
      error: teacherError,
    } = await supabaseAdmin
      .from("teachers")
      .select("id, name, session_price, currency, is_active")
      .eq("id", teacherId)
      .maybeSingle();

    if (teacherError || !teacher) {
      return jsonResponse(
        {
          error: "Öğretmen bulunamadı.",
        },
        404,
      );
    }

    if (teacher.is_active !== true) {
      return jsonResponse(
        {
          error: "Bu öğretmen şu anda aktif değil.",
        },
        400,
      );
    }

    const realPrice = Number(teacher.session_price || 0);
    const realCurrency = teacher.currency?.toString().toLowerCase() || "try";

    if (realPrice <= 0) {
      return jsonResponse(
        {
          error: "Bu öğretmen için seans ücreti belirlenmemiş.",
        },
        400,
      );
    }

    if (realCurrency !== currency) {
      return jsonResponse(
        {
          error: "Para birimi uyuşmuyor.",
        },
        400,
      );
    }

    if (Math.round(realPrice * 100) !== amountMinor) {
      return jsonResponse(
        {
          error: "Ödeme tutarı güncel öğretmen ücretiyle uyuşmuyor.",
        },
        400,
      );
    }

    const {
      data: existingSession,
      error: existingSessionError,
    } = await supabaseAdmin
      .from("sessions")
      .select("id")
      .eq("teacher_id", teacherId)
      .eq("session_date", sessionDate)
      .eq("session_time", sessionTime)
      .eq("status", "upcoming")
      .maybeSingle();

    if (existingSessionError) {
      return jsonResponse(
        {
          error: "Seans uygunluğu kontrol edilemedi.",
        },
        500,
      );
    }

    if (existingSession) {
      return jsonResponse(
        {
          error: "Bu saat az önce doldu. Lütfen başka bir saat seç.",
        },
        409,
      );
    }

    const {
      data: payment,
      error: paymentError,
    } = await supabaseAdmin
      .from("payments")
      .insert({
        user_id: userId,
        teacher_id: teacherId,
        teacher_name: teacherName,
        session_date: sessionDate,
        session_time: sessionTime,
        amount: realPrice,
        currency: realCurrency,
        status: "pending",
        notes,
      })
      .select()
      .single();

    if (paymentError || !payment) {
      return jsonResponse(
        {
          error: "Ödeme kaydı oluşturulamadı.",
          detail: paymentError?.message,
        },
        500,
      );
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountMinor,
      currency: realCurrency,
      automatic_payment_methods: {
        enabled: true,
      },
      metadata: {
        source: "bagnu_theta",
        payment_id: payment.id,
        user_id: userId,
        teacher_id: teacherId,
        teacher_name: teacherName,
        session_date: sessionDate,
        session_time: sessionTime,
      },
    });

    const {
      error: updatePaymentError,
    } = await supabaseAdmin
      .from("payments")
      .update({
        stripe_payment_intent_id: paymentIntent.id,
        stripe_client_secret: paymentIntent.client_secret,
      })
      .eq("id", payment.id);

    if (updatePaymentError) {
      return jsonResponse(
        {
          error: "Ödeme bilgisi güncellenemedi.",
          detail: updatePaymentError.message,
        },
        500,
      );
    }

    return jsonResponse({
      paymentId: payment.id,
      paymentIntentId: paymentIntent.id,
      clientSecret: paymentIntent.client_secret,
      amount: realPrice,
      currency: realCurrency,
    });
  } catch (error) {
    return jsonResponse(
      {
        error: error instanceof Error ? error.message : "Bilinmeyen hata.",
      },
      500,
    );
  }
});