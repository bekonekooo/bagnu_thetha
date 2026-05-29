import 'dart:async';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_application_1/features/sessions/data/models/session_model.dart';
import 'package:flutter_application_1/features/video_call/data/services/video_call_service.dart';

class VideoCallPage extends StatefulWidget {
  final SessionModel session;
  final String participantName;

  const VideoCallPage({
    super.key,
    required this.session,
    required this.participantName,
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  final VideoCallService videoCallService = VideoCallService();
  final Room room = Room();

  bool isConnecting = true;
  bool isConnected = false;
  bool isCameraEnabled = true;
  bool isMicrophoneEnabled = true;

  String? errorMessage;
  String? roomName;

  @override
  void initState() {
    super.initState();
    room.addListener(onRoomChanged);
    connectToRoom();
  }

  void onRoomChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> connectToRoom() async {
    try {
      setState(() {
        isConnecting = true;
        errorMessage = null;
      });

      final hasPermissions = await requestPermissions();

      if (!hasPermissions) {
        throw Exception('Kamera ve mikrofon izni verilmedi.');
      }

      final tokenResponse = await videoCallService.createLiveKitToken(
        sessionId: widget.session.id,
        participantName: widget.participantName,
      );

      roomName = tokenResponse.roomName;

      await room.connect(
        tokenResponse.url,
        tokenResponse.token,
      );

      final localParticipant = room.localParticipant;

      await localParticipant?.setCameraEnabled(true);
      await localParticipant?.setMicrophoneEnabled(true);

      if (!mounted) return;

      setState(() {
        isConnecting = false;
        isConnected = true;
        isCameraEnabled = true;
        isMicrophoneEnabled = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isConnecting = false;
        isConnected = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<bool> requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

    return cameraStatus.isGranted && microphoneStatus.isGranted;
  }

  Future<void> toggleCamera() async {
    final localParticipant = room.localParticipant;
    if (localParticipant == null) return;

    final nextValue = !isCameraEnabled;

    try {
      await localParticipant.setCameraEnabled(nextValue);

      if (!mounted) return;

      setState(() {
        isCameraEnabled = nextValue;
      });
    } catch (e) {
      showError('Kamera değiştirilemedi: $e');
    }
  }

  Future<void> toggleMicrophone() async {
    final localParticipant = room.localParticipant;
    if (localParticipant == null) return;

    final nextValue = !isMicrophoneEnabled;

    try {
      await localParticipant.setMicrophoneEnabled(nextValue);

      if (!mounted) return;

      setState(() {
        isMicrophoneEnabled = nextValue;
      });
    } catch (e) {
      showError('Mikrofon değiştirilemedi: $e');
    }
  }

  Future<void> leaveRoom() async {
    try {
      await room.disconnect();
    } catch (_) {}

    if (!mounted) return;
    Navigator.pop(context);
  }

  void showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  List<Participant> getParticipants() {
    final participants = <Participant>[];

    final localParticipant = room.localParticipant;

    if (localParticipant != null) {
      participants.add(localParticipant);
    }

    participants.addAll(room.remoteParticipants.values);

    return participants;
  }

  @override
  void dispose() {
    room.removeListener(onRoomChanged);
    unawaited(room.disconnect());
    unawaited(room.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final participants = getParticipants();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Görüntülü Ders'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: leaveRoom,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: isConnecting
            ? buildLoadingState()
            : errorMessage != null
                ? buildErrorState()
                : Column(
                    children: [
                      Expanded(
                        child: participants.isEmpty
                            ? buildWaitingState()
                            : buildVideoGrid(participants),
                      ),
                      buildBottomControls(),
                    ],
                  ),
      ),
    );
  }

  Widget buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.white,
          ),
          SizedBox(height: 18),
          Text(
            'Görüntülü ders odasına bağlanılıyor...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 42,
              ),
              const SizedBox(height: 12),
              const Text(
                'Görüntülü görüşme başlatılamadı',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage ?? 'Bilinmeyen hata',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: connectToRoom,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: leaveRoom,
                  icon: const Icon(Icons.close),
                  label: const Text('Çık'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildWaitingState() {
    return const Center(
      child: Text(
        'Katılımcılar bekleniyor...',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget buildVideoGrid(List<Participant> participants) {
    if (participants.length == 1) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: ParticipantVideoTile(
          participant: participants.first,
          isLocal: participants.first == room.localParticipant,
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: participants.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final participant = participants[index];

        return ParticipantVideoTile(
          participant: participant,
          isLocal: participant == room.localParticipant,
        );
      },
    );
  }

  Widget buildBottomControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          buildControlButton(
            icon: isMicrophoneEnabled ? Icons.mic : Icons.mic_off,
            label: isMicrophoneEnabled ? 'Mikrofon' : 'Kapalı',
            color: isMicrophoneEnabled ? Colors.white : Colors.red,
            onTap: toggleMicrophone,
          ),
          buildControlButton(
            icon: isCameraEnabled ? Icons.videocam : Icons.videocam_off,
            label: isCameraEnabled ? 'Kamera' : 'Kapalı',
            color: isCameraEnabled ? Colors.white : Colors.red,
            onTap: toggleCamera,
          ),
          buildControlButton(
            icon: Icons.call_end,
            label: 'Bitir',
            color: Colors.red,
            onTap: leaveRoom,
          ),
        ],
      ),
    );
  }

  Widget buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color.withOpacity(0.14),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ParticipantVideoTile extends StatefulWidget {
  final Participant participant;
  final bool isLocal;

  const ParticipantVideoTile({
    super.key,
    required this.participant,
    required this.isLocal,
  });

  @override
  State<ParticipantVideoTile> createState() => _ParticipantVideoTileState();
}

class _ParticipantVideoTileState extends State<ParticipantVideoTile> {
  TrackPublication? videoPublication;

  @override
  void initState() {
    super.initState();
    widget.participant.addListener(onParticipantChanged);
    onParticipantChanged();
  }

  @override
  void didUpdateWidget(covariant ParticipantVideoTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.participant != widget.participant) {
      oldWidget.participant.removeListener(onParticipantChanged);
      widget.participant.addListener(onParticipantChanged);
      onParticipantChanged();
    }
  }

  @override
  void dispose() {
    widget.participant.removeListener(onParticipantChanged);
    super.dispose();
  }

  void onParticipantChanged() {
    final subscribedVideos = widget.participant.trackPublications.values.where(
      (publication) {
        return publication.kind == TrackType.VIDEO &&
            publication.subscribed &&
            !publication.muted;
      },
    ).toList();

    if (!mounted) return;

    setState(() {
      if (subscribedVideos.isNotEmpty) {
        videoPublication = subscribedVideos.first;
      } else {
        videoPublication = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final track = videoPublication?.track;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.isLocal ? Colors.deepPurpleAccent : Colors.white24,
          width: widget.isLocal ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: track is VideoTrack
                ? VideoTrackRenderer(track)
                : buildNoVideoPlaceholder(),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.58),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.isLocal
                    ? 'Sen'
                    : widget.participant.name.isNotEmpty
                        ? widget.participant.name
                        : widget.participant.identity,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildNoVideoPlaceholder() {
    return Container(
      color: const Color(0xFF212121),
      child: Center(
        child: CircleAvatar(
          radius: 34,
          backgroundColor: Colors.deepPurple.shade300,
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 34,
          ),
        ),
      ),
    );
  }
}