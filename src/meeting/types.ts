/**
 * 会议参数协议（与前端 MeetingManager 的 startMeeting/updateMeetingInfo 契约对齐）。
 *
 * 旧 EEUI 的字段集（resources/mobile/.legacy-eeui/src/pages/compoment/meetings.vue#joint）：
 *   { name, token, channel, uuid, appid, avatar, username, video, audio, meetingid, sharelink, alert }
 *
 * native→web 事件 __onMeetingEvent({act, uuid, ...})：
 *   - 'success' 加入成功
 *   - 'error'   加入失败
 *   - 'status'  会议显示/隐藏状态切换
 *   - 'invent'  点击邀请
 *   - 'getInfo' 请求获取某用户的昵称/头像（前端补 updateMeetingInfo 回填）
 *   - 'endMeeting' 会议结束/离开
 */

export interface MeetingAlert {
  title?: string;
  message?: string;
  cancel?: string;
  confirm?: string;
}

export interface StartMeetingParams {
  name?: string;
  /** Agora token */
  token: string;
  /** Agora channel name（频道名） */
  channel: string;
  /** Agora uid（数字） */
  uuid: number;
  /** Agora App ID */
  appid: string;
  avatar?: string;
  username?: string;
  video?: boolean;
  audio?: boolean;
  meetingid?: number | string;
  sharelink?: string;
  alert?: MeetingAlert;
}

export interface MeetingMemberInfo {
  uuid: number;
  nickname?: string;
  avatar?: string;
}

export interface UpdateMeetingInfoArgs {
  infos: MeetingMemberInfo[];
}

export type MeetingEventAct =
  | 'success'
  | 'error'
  | 'status'
  | 'invent'
  | 'getInfo'
  | 'endMeeting';

export interface MeetingEventPayload {
  act: MeetingEventAct;
  uuid?: number;
  meetingid?: number | string;
  status?: 'visible' | 'hidden';
  [k: string]: unknown;
}
