import { registerRootComponent } from 'expo';

import App from './App';

// registerRootComponent 等价于 AppRegistry.registerComponent('main', () => App)，
// 并确保在原生构建与开发环境下入口一致。
registerRootComponent(App);
