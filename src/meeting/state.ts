/**
 * 会议全局状态：跨 RPC handler 与 UI 组件共享。
 *
 * 单实例：同一时刻只可能有一个进行中的会议（与旧 EEUI 行为一致）。
 * 用最朴素的 listener 模式（避免引入 zustand 等额外依赖）。
 */
import type { MeetingMemberInfo, StartMeetingParams } from './types';

interface MeetingState {
  visible: boolean;
  params: StartMeetingParams | null;
  members: Map<number, MeetingMemberInfo>;
}

const state: MeetingState = {
  visible: false,
  params: null,
  members: new Map(),
};

type Listener = (s: MeetingState) => void;
const listeners = new Set<Listener>();

function emitChange(): void {
  for (const fn of listeners) fn(state);
}

export function subscribeMeeting(fn: Listener): () => void {
  listeners.add(fn);
  fn(state);
  return () => {
    listeners.delete(fn);
  };
}

export function startMeetingState(p: StartMeetingParams): void {
  state.params = p;
  state.visible = true;
  state.members.clear();
  emitChange();
}

export function stopMeetingState(): void {
  state.visible = false;
  state.params = null;
  state.members.clear();
  emitChange();
}

export function updateMembers(infos: MeetingMemberInfo[]): void {
  for (const info of infos) {
    if (typeof info?.uuid !== 'number') continue;
    state.members.set(info.uuid, info);
  }
  emitChange();
}

export function getMeetingState(): MeetingState {
  return state;
}
