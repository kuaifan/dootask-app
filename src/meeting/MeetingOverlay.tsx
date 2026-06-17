/**
 * WS5 会议浮层：订阅 meeting state，按需拉起/销毁 Agora 引擎并渲染最小 UI。
 *
 * 本期范围：可用骨架（加入/离开 + 音视频开关 + 切摄像头 + 本地+远端视频）。
 * 未做的（标注为后续迭代）：参与者头像列表、浮窗最小化、邀请按钮、网络指示器。
 */
import { useEffect, useRef, useState } from 'react';
import {
  Modal,
  Platform,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { activateKeepAwakeAsync, deactivateKeepAwake } from 'expo-keep-awake';
import {
  ChannelProfileType,
  ClientRoleType,
  createAgoraRtcEngine,
  type IRtcEngine,
  RtcSurfaceView,
} from 'react-native-agora';
import { emitNative } from '../native/shared';
import { subscribeMeeting, stopMeetingState } from './state';
import type { StartMeetingParams } from './types';

interface RemoteUser {
  uid: number;
}

function emitEvent(act: string, extra: Record<string, unknown> = {}): void {
  emitNative('__onMeetingEvent', { act, ...extra });
}

export function MeetingOverlay() {
  const [params, setParams] = useState<StartMeetingParams | null>(null);
  const [visible, setVisible] = useState(false);
  const [audioOn, setAudioOn] = useState(true);
  const [videoOn, setVideoOn] = useState(true);
  const [remoteUsers, setRemoteUsers] = useState<RemoteUser[]>([]);
  const engineRef = useRef<IRtcEngine | null>(null);

  useEffect(() => {
    return subscribeMeeting((s) => {
      setParams(s.params);
      setVisible(s.visible);
    });
  }, []);

  // 拉起 / 销毁 Agora 引擎
  useEffect(() => {
    if (!visible || !params) {
      teardown();
      return;
    }
    setAudioOn(params.audio !== false);
    setVideoOn(params.video !== false);
    setRemoteUsers([]);
    void setup(params);
    void activateKeepAwakeAsync('meeting');
    return () => {
      deactivateKeepAwake('meeting');
      teardown();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [visible, params?.channel, params?.token]);

  async function setup(p: StartMeetingParams): Promise<void> {
    try {
      const engine = createAgoraRtcEngine();
      engineRef.current = engine;
      engine.initialize({ appId: p.appid, channelProfile: ChannelProfileType.ChannelProfileCommunication });

      engine.registerEventHandler({
        onJoinChannelSuccess: () => {
          emitEvent('success', { uuid: p.uuid, meetingid: p.meetingid });
        },
        onError: (err) => {
          emitEvent('error', { uuid: p.uuid, code: err });
        },
        onUserJoined: (_conn, uid) => {
          setRemoteUsers((prev) => (prev.find((u) => u.uid === uid) ? prev : [...prev, { uid }]));
          emitEvent('getInfo', { uuid: uid });
        },
        onUserOffline: (_conn, uid) => {
          setRemoteUsers((prev) => prev.filter((u) => u.uid !== uid));
        },
      });

      if (p.video !== false) {
        engine.enableVideo();
      } else {
        engine.disableVideo();
      }
      if (p.audio !== false) {
        engine.enableAudio();
      } else {
        engine.disableAudio();
      }
      // 频道身份：双向通讯
      engine.setClientRole(ClientRoleType.ClientRoleBroadcaster);
      engine.joinChannel(p.token, p.channel, p.uuid, {});
      emitEvent('status', { status: 'visible' });
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'agora init failed';
      emitEvent('error', { uuid: p.uuid, message: msg });
    }
  }

  function teardown(): void {
    const engine = engineRef.current;
    engineRef.current = null;
    if (engine) {
      try {
        engine.leaveChannel();
      } catch {
        // 忽略 leaveChannel 异常
      }
      try {
        engine.release();
      } catch {
        // 忽略 release 异常
      }
    }
  }

  function leave(): void {
    emitEvent('endMeeting', { uuid: params?.uuid, meetingid: params?.meetingid });
    emitEvent('status', { status: 'hidden' });
    stopMeetingState();
  }

  function toggleAudio(): void {
    const next = !audioOn;
    setAudioOn(next);
    engineRef.current?.muteLocalAudioStream(!next);
  }

  function toggleVideo(): void {
    const next = !videoOn;
    setVideoOn(next);
    engineRef.current?.muteLocalVideoStream(!next);
  }

  function switchCamera(): void {
    engineRef.current?.switchCamera();
  }

  if (!visible || !params) return null;

  return (
    <Modal visible={visible} animationType="slide" onRequestClose={leave} statusBarTranslucent>
      <View style={styles.container}>
        <View style={styles.videoArea}>
          <View style={styles.localVideoWrap}>
            {videoOn ? (
              <RtcSurfaceView canvas={{ uid: 0 }} style={styles.video} />
            ) : (
              <View style={[styles.video, styles.videoOff]}>
                <Text style={styles.videoOffText}>{params.username ?? '本地'}（视频关闭）</Text>
              </View>
            )}
          </View>
          {remoteUsers.map((u) => (
            <View key={u.uid} style={styles.remoteVideoWrap}>
              <RtcSurfaceView canvas={{ uid: u.uid }} style={styles.video} />
            </View>
          ))}
        </View>
        <View style={styles.controls}>
          <Btn label={audioOn ? '静音' : '取消静音'} onPress={toggleAudio} />
          <Btn label={videoOn ? '关视频' : '开视频'} onPress={toggleVideo} />
          {Platform.OS !== 'web' && <Btn label="切换摄像头" onPress={switchCamera} />}
          <Btn label="离开" onPress={leave} danger />
        </View>
      </View>
    </Modal>
  );
}

function Btn({ label, onPress, danger }: { label: string; onPress: () => void; danger?: boolean }) {
  return (
    <TouchableOpacity onPress={onPress} style={[styles.btn, danger && styles.btnDanger]}>
      <Text style={styles.btnText}>{label}</Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#000' },
  videoArea: { flex: 1, flexDirection: 'row', flexWrap: 'wrap' },
  localVideoWrap: { width: '50%', aspectRatio: 3 / 4 },
  remoteVideoWrap: { width: '50%', aspectRatio: 3 / 4 },
  video: { flex: 1, backgroundColor: '#222' },
  videoOff: { alignItems: 'center', justifyContent: 'center' },
  videoOffText: { color: '#aaa' },
  controls: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingVertical: 16,
    paddingBottom: 32,
    backgroundColor: '#111',
  },
  btn: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    backgroundColor: '#333',
    borderRadius: 24,
  },
  btnDanger: { backgroundColor: '#c62828' },
  btnText: { color: '#fff', fontWeight: '600' },
});
