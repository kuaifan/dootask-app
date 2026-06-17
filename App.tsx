import { StatusBar } from 'expo-status-bar';
import { StyleSheet, View } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { WebViewShell } from './src/webview/WebViewShell';
import { registerNativeHandlers } from './src/native';
import { MeetingOverlay } from './src/meeting';

// App 启动一次性注册所有桥接 handler（device/ui/storage/media/link/notify/push/meeting）。
registerNativeHandlers();

export default function App() {
  return (
    <SafeAreaProvider>
      <View style={styles.flex}>
        <StatusBar style="auto" translucent />
        <WebViewShell />
        <MeetingOverlay />
      </View>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  flex: {
    flex: 1,
  },
});
