
import { useColorScheme } from "react-native";
import { Stack, router } from "expo-router";
import "react-native-reanimated";
import {
  DarkTheme,
  DefaultTheme,
  Theme,
  ThemeProvider,
} from "@react-navigation/native";
import { StatusBar } from "expo-status-bar";
import { Button } from "@/components/button";
import * as SplashScreen from "expo-splash-screen";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { useFonts, OpenSans_400Regular, OpenSans_600SemiBold, OpenSans_700Bold } from '@expo-google-fonts/open-sans';
import { PlayfairDisplay_400Regular, PlayfairDisplay_700Bold } from '@expo-google-fonts/playfair-display';
import { SystemBars } from "react-native-edge-to-edge";
import { useEffect } from "react";

// Prevent the splash screen from auto-hiding before asset loading is complete.
SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [loaded] = useFonts({
    OpenSans_400Regular,
    OpenSans_600SemiBold,
    OpenSans_700Bold,
    PlayfairDisplay_400Regular,
    PlayfairDisplay_700Bold,
  });

  const colorScheme = useColorScheme();

  useEffect(() => {
    if (loaded) {
      SplashScreen.hideAsync();
    }
  }, [loaded]);

  if (!loaded) {
    return null;
  }

  // Custom light theme for the palm reading app
  const PalmReadingTheme: Theme = {
    ...DefaultTheme,
    colors: {
      ...DefaultTheme.colors,
      primary: '#6B4423',
      background: '#F5F1E8',
      card: '#FFFFFF',
      text: '#5D4037',
      border: '#D4C4A8',
      notification: '#6B4423',
    },
  };

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <ThemeProvider value={PalmReadingTheme}>
        <SystemBars style="dark" />
        <Stack>
          <Stack.Screen name="(index)" options={{ headerShown: false }} />
          <Stack.Screen 
            name="camera" 
            options={{ 
              presentation: 'modal',
              headerShown: true,
            }} 
          />
          <Stack.Screen 
            name="results" 
            options={{ 
              presentation: 'modal',
              headerShown: true,
            }} 
          />
          <Stack.Screen 
            name="history" 
            options={{ 
              presentation: 'modal',
              headerShown: true,
            }} 
          />
        </Stack>
        <StatusBar style="dark" />
      </ThemeProvider>
    </GestureHandlerRootView>
  );
}
