
import React from 'react';
import { View, Text, StyleSheet, Pressable } from 'react-native';
import { router } from 'expo-router';
import { colors } from '@/styles/commonStyles';

interface AdBannerProps {
  style?: any;
  showRemoveAds?: boolean;
}

export default function AdBanner({ style, showRemoveAds = true }: AdBannerProps) {
  console.log('AdBanner rendered');

  const handlePremiumPress = () => {
    console.log('Navigate to premium from ad banner');
    router.push('/premium');
  };

  return (
    <View style={[styles.container, style]}>
      <Text style={styles.adText}>📱 Advertisement Space</Text>
      <Text style={styles.adSubtext}>
        This is where ads would appear in the free version
      </Text>
      {showRemoveAds && (
        <Pressable onPress={handlePremiumPress} style={styles.removeAdsButton}>
          <Text style={styles.removeAdsText}>Remove ads with Premium →</Text>
        </Pressable>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: 'rgba(255, 255, 255, 0.8)',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.accent,
    borderStyle: 'dashed',
    marginVertical: 10,
  },
  adText: {
    fontSize: 14,
    color: colors.textLight,
    marginBottom: 4,
    fontWeight: '500',
  },
  adSubtext: {
    fontSize: 12,
    color: colors.textLight,
    textAlign: 'center',
    marginBottom: 8,
  },
  removeAdsButton: {
    paddingVertical: 4,
    paddingHorizontal: 8,
  },
  removeAdsText: {
    fontSize: 12,
    color: colors.primary,
    fontWeight: '600',
  },
});
