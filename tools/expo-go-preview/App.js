import React, { useState } from 'react';
import { ActivityIndicator, Pressable, StyleSheet, Text, View } from 'react-native';
import { WebView } from 'react-native-webview';
import { resolvePreviewUrl } from './preview-url';

const preview = resolvePreviewUrl(process.env.EXPO_PUBLIC_FLUTTER_WEB_URL);

function allowedNavigation(request) {
  if (request.url === 'about:blank') return true;
  if (!preview.url) return false;
  try {
    return new URL(request.url).origin === new URL(preview.url).origin;
  } catch (_) {
    return false;
  }
}

export default function App() {
  const [loading, setLoading] = useState(Boolean(preview.url));
  const [problem, setProblem] = useState(preview.error);
  const [reloadKey, setReloadKey] = useState(0);

  function retry() {
    setProblem(null);
    setLoading(true);
    setReloadKey((value) => value + 1);
  }

  return (
    <View style={styles.root}>
      {preview.url && (
        <WebView
          key={reloadKey}
          style={styles.web}
          source={{ uri: preview.url }}
          originWhitelist={[new URL(preview.url).origin]}
          onShouldStartLoadWithRequest={allowedNavigation}
          javaScriptEnabled
          domStorageEnabled
          sharedCookiesEnabled={false}
          thirdPartyCookiesEnabled={false}
          cacheEnabled={false}
          incognito
          setSupportMultipleWindows={false}
          onLoadStart={() => setLoading(true)}
          onLoadEnd={() => setLoading(false)}
          onError={() => {
            setLoading(false);
            setProblem('Cannot reach Flutter Web. Check that its terminal is running and both devices use the same private network.');
          }}
          onHttpError={(event) => {
            if (event.nativeEvent.statusCode >= 400) {
              setLoading(false);
              setProblem('Flutter Web server returned HTTP ' + event.nativeEvent.statusCode + '.');
            }
          }}
        />
      )}
      {loading && !problem && (
        <View pointerEvents="none" style={styles.busy}>
          <ActivityIndicator size="large" />
        </View>
      )}
      {problem && (
        <View style={styles.error}>
          <Text style={styles.title}>Tio Flutter Web preview</Text>
          <Text style={styles.body}>{problem}</Text>
          <Text style={styles.note}>Test only. Flutter native app and data are unchanged. No account or private health data should be used.</Text>
          {preview.url && (
            <Pressable accessibilityRole="button" style={styles.retry} onPress={retry}>
              <Text style={styles.retryText}>Retry preview</Text>
            </Pressable>
          )}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#101010' },
  web: { flex: 1, backgroundColor: '#101010' },
  busy: { ...StyleSheet.absoluteFillObject, alignItems: 'center', justifyContent: 'center', backgroundColor: '#101010' },
  error: { ...StyleSheet.absoluteFillObject, alignItems: 'center', justifyContent: 'center', padding: 24, backgroundColor: '#101010' },
  title: { color: '#FFFFFF', fontSize: 20, fontWeight: '600', marginBottom: 16, textAlign: 'center' },
  body: { color: '#FFFFFF', fontSize: 15, textAlign: 'center', marginBottom: 12 },
  note: { color: '#CCCCCC', fontSize: 12, textAlign: 'center', marginBottom: 24 },
  retry: { paddingVertical: 12, paddingHorizontal: 20, borderRadius: 10, borderWidth: 1, borderColor: '#888888' },
  retryText: { color: '#FFFFFF', fontWeight: '600' }
});
