
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

  // Custom dark theme for the palm reading app
  const PalmReadingDarkTheme: Theme = {
    ...DarkTheme,
    colors: {
      ...DarkTheme.colors,
      primary: '#D4A574',
      background: '#1A1A1A',
      card: '#2A2A2A',
      text: '#E8D5B7',
      border: '#4A4A4A',
      notification: '#D4A574',
    },
  };

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <ThemeProvider value={colorScheme === 'dark' ? PalmReadingDarkTheme : PalmReadingTheme}>
        <SystemBars style={colorScheme === 'dark' ? "light" : "dark"} />
        <Stack>
          <Stack.Screen name="(index)" options={{ headerShown: false }} />
          <Stack.Screen 
            name="camera" 
            options={{ 
              headerShown: true,
              title: "Capture Palm",
              headerStyle: {
                backgroundColor: colorScheme === 'dark' ? '#2A2A2A' : '#F5F1E8',
              },
              headerTintColor: colorScheme === 'dark' ? '#E8D5B7' : '#5D4037',
              headerTitleStyle: {
                fontFamily: 'PlayfairDisplay_700Bold',
                fontSize: 20,
              },
              headerBackTitle: "Back",
            }} 
          />
          <Stack.Screen 
            name="results" 
            options={{ 
              headerShown: true,
              title: "Your Reading",
              headerStyle: {
                backgroundColor: colorScheme === 'dark' ? '#2A2A2A' : '#F5F1E8',
              },
              headerTintColor: colorScheme === 'dark' ? '#E8D5B7' : '#5D4037',
              headerTitleStyle: {
                fontFamily: 'PlayfairDisplay_700Bold',
                fontSize: 20,
              },
              headerBackTitle: "Back",
            }} 
          />
          <Stack.Screen 
            name="history" 
            options={{ 
              headerShown: true,
              title: "Reading History",
              headerStyle: {
                backgroundColor: colorScheme === 'dark' ? '#2A2A2A' : '#F5F1E8',
              },
              headerTintColor: colorScheme === 'dark' ? '#E8D5B7' : '#5D4037',
              headerTitleStyle: {
                fontFamily: 'PlayfairDisplay_700Bold',
                fontSize: 20,
              },
              headerBackTitle: "Back",
            }} 
          />
          <Stack.Screen 
            name="premium" 
            options={{ 
              headerShown: true,
              title: "Premium",
              headerStyle: {
                backgroundColor: colorScheme === 'dark' ? '#2A2A2A' : '#F5F1E8',
              },
              headerTintColor: colorScheme === 'dark' ? '#E8D5B7' : '#5D4037',
              headerTitleStyle: {
                fontFamily: 'PlayfairDisplay_700Bold',
                fontSize: 20,
              },
              headerBackTitle: "Back",
            }} 
          />
        </Stack>
        <StatusBar style={colorScheme === 'dark' ? "light" : "dark"} />
      </ThemeProvider>
    </GestureHandlerRootView>
  );
}
