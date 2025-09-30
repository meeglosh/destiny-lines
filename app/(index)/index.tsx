
import React from 'react';
import { View, Text, StyleSheet, Pressable } from 'react-native';
import { router, Stack } from 'expo-router';
import { commonStyles, colors, textStyles, buttonStyles } from '@/styles/commonStyles';
import { Button } from '@/components/button';
import { LinearGradient } from 'expo-linear-gradient';

export default function HomeScreen() {
  console.log('HomeScreen rendered');

  const handleStartReading = () => {
    console.log('Navigate to camera screen');
    router.push('/camera');
  };

  const handleViewHistory = () => {
    console.log('Navigate to history screen');
    router.push('/history');
  };

  const handlePremium = () => {
    console.log('Navigate to premium screen');
    router.push('/premium');
  };

  return (
    <View style={commonStyles.wrapper}>
      <Stack.Screen 
        options={{ 
          title: 'Destiny Lines',
          headerStyle: { backgroundColor: colors.background },
          headerTintColor: colors.text,
          headerTitleStyle: { fontWeight: 'bold' },
          headerRight: () => (
            <Pressable onPress={handlePremium} style={styles.premiumButton}>
              <Text style={styles.premiumButtonText}>✨ Premium</Text>
            </Pressable>
          ),
        }} 
      />
      
      <LinearGradient
        colors={['#F5F1E8', '#E8DCC6', '#D4C4A8']}
        style={styles.container}
      >
        {/* Header Section */}
        <View style={styles.headerSection}>
          <Text style={styles.appTitle}>✋ Destiny Lines</Text>
          <Text style={styles.subtitle}>Discover Your Palm&apos;s Secrets</Text>
          <Text style={styles.description}>
            Let AI reveal the mysteries hidden in the lines of your palm
          </Text>
        </View>

        {/* Main Action Section */}
        <View style={styles.actionSection}>
          <View style={styles.palmIcon}>
            <Text style={styles.palmEmoji}>🔮</Text>
          </View>
          
          <Button
            onPress={handleStartReading}
            style={styles.primaryButton}
            textStyle={styles.primaryButtonText}
          >
            Start Palm Reading
          </Button>
          
          <Pressable onPress={handleViewHistory} style={styles.secondaryButton}>
            <Text style={styles.secondaryButtonText}>View Past Readings</Text>
          </Pressable>
        </View>

        {/* Features Section */}
        <View style={styles.featuresSection}>
          <View style={styles.feature}>
            <Text style={styles.featureIcon}>🌿</Text>
            <Text style={styles.featureText}>Life Line Analysis</Text>
          </View>
          <View style={styles.feature}>
            <Text style={styles.featureIcon}>🧠</Text>
            <Text style={styles.featureText}>Head Line Insights</Text>
          </View>
          <View style={styles.feature}>
            <Text style={styles.featureIcon}>❤️</Text>
            <Text style={styles.featureText}>Heart Line Reading</Text>
          </View>
        </View>

        {/* Ad Banner Placeholder */}
        <View style={styles.adBanner}>
          <Text style={styles.adText}>📱 Advertisement Space</Text>
          <Pressable onPress={handlePremium}>
            <Text style={styles.removeAdsText}>Remove ads with Premium →</Text>
          </Pressable>
        </View>
      </LinearGradient>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingHorizontal: 20,
    paddingTop: 40,
    paddingBottom: 20,
  },
  premiumButton: {
    backgroundColor: colors.primary,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 15,
    marginRight: 10,
  },
  premiumButtonText: {
    color: colors.white,
    fontSize: 14,
    fontWeight: 'bold',
  },
  headerSection: {
    alignItems: 'center',
    marginBottom: 40,
  },
  appTitle: {
    ...textStyles.title,
    fontSize: 32,
    marginBottom: 8,
  },
  subtitle: {
    ...textStyles.subtitle,
    marginBottom: 16,
  },
  description: {
    ...textStyles.body,
    textAlign: 'center',
    paddingHorizontal: 20,
  },
  actionSection: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 30,
  },
  palmIcon: {
    width: 120,
    height: 120,
    borderRadius: 60,
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 40,
    ...commonStyles.shadow,
  },
  palmEmoji: {
    fontSize: 60,
  },
  primaryButton: {
    ...buttonStyles.primary,
    width: '100%',
    maxWidth: 300,
    marginBottom: 16,
  },
  primaryButtonText: {
    ...textStyles.buttonPrimary,
  },
  secondaryButton: {
    paddingVertical: 12,
    paddingHorizontal: 30,
  },
  secondaryButtonText: {
    ...textStyles.caption,
    color: colors.textSecondary,
    textDecorationLine: 'underline',
    fontSize: 16,
  },
  featuresSection: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingHorizontal: 20,
    marginBottom: 20,
  },
  feature: {
    alignItems: 'center',
    flex: 1,
  },
  featureIcon: {
    fontSize: 24,
    marginBottom: 8,
  },
  featureText: {
    fontSize: 12,
    color: colors.textSecondary,
    textAlign: 'center',
    fontWeight: '500',
  },
  adBanner: {
    backgroundColor: 'rgba(255, 255, 255, 0.8)',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.accent,
    borderStyle: 'dashed',
  },
  adText: {
    fontSize: 14,
    color: colors.textLight,
    marginBottom: 4,
  },
  removeAdsText: {
    fontSize: 12,
    color: colors.primary,
    fontWeight: '600',
  },
});
