
import React from "react";
import { useNetworkState } from "expo-network";
import { Redirect, router, Stack } from "expo-router";
import { Alert } from "react-native";
import { Button } from "@/components/button";
import { WidgetProvider } from "@/contexts/WidgetContext";

export const unstable_settings = {
  initialRouteName: "index",
};

export default function AppIndexLayout() {
  const networkState = useNetworkState();

  React.useEffect(() => {
    if (
      !networkState.isConnected &&
      networkState.isInternetReachable === false
    ) {
      Alert.alert(
        "🔌 You are offline",
        "You can keep using the app! Your changes will be saved locally and synced when you are back online."
      );
    }
  }, [networkState.isConnected, networkState.isInternetReachable]);

  return (
    <WidgetProvider>
      <Stack
        screenOptions={{
          headerShown: false, // Disable default headers to prevent conflicts
        }}
      >
        {/* All screens will handle their own headers */}
      </Stack>
    </WidgetProvider>
  );
}
