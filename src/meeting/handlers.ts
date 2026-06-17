/**
 * WS5 会议桥接 handler：把 Web 端的 startMeeting / updateMeetingInfo 接到本地状态。
 *
 * UI（MeetingOverlay）订阅状态变更，自动显示/隐藏 + 拉起 react-native-agora。
 */
import { registerHandlers } from '../bridge';
import { startMeetingState, stopMeetingState, updateMembers } from './state';
import type { StartMeetingParams, UpdateMeetingInfoArgs } from './types';

export function registerMeetingHandlers(): void {
  registerHandlers({
    startMeeting: (args: { meetingParams: StartMeetingParams } | StartMeetingParams) => {
      // 兼容两种入参形态：旧契约是 { meetingParams: {...} }
      const p =
        args && typeof args === 'object' && 'meetingParams' in args
          ? (args as { meetingParams: StartMeetingParams }).meetingParams
          : (args as StartMeetingParams);
      if (!p?.token || !p?.channel || !p?.appid) {
        throw new Error('startMeeting: token/channel/appid required');
      }
      startMeetingState(p);
    },

    updateMeetingInfo: (args: UpdateMeetingInfoArgs) => {
      if (!args?.infos) return;
      updateMembers(args.infos);
    },

    /** 显式结束（测试/前端主动调用） */
    leaveMeeting: () => {
      stopMeetingState();
    },
  });
}
