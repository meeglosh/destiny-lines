
import React from 'react';
import { View, Text, StyleSheet, Pressable, SafeAreaView, Platform, Image } from 'react-native';
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
    <SafeAreaView style={commonStyles.wrapper}>
      <LinearGradient
        colors={['#F5F1E8', '#E8DCC6', '#D4C4A8']}
        style={styles.container}
      >
        {/* Custom Header */}
        <View style={styles.header}>
          <View style={styles.headerContent}>
            <Text style={styles.headerTitle}>✋ Destiny Lines</Text>
            <Pressable onPress={handlePremium} style={styles.premiumButton}>
              <Text style={styles.premiumButtonText}>✨ Premium</Text>
            </Pressable>
          </View>
        </View>

        {/* Main Content */}
        <View style={styles.content}>
          {/* Header Section */}
          <View style={styles.headerSection}>
            <Text style={styles.subtitle}>Discover Your Palm&apos;s Secrets</Text>
            <Text style={styles.description}>
              Let AI reveal the mysteries hidden in the lines of your palm
            </Text>
          </View>

          {/* Main Action Section */}
          <View style={styles.actionSection}>
            <View style={styles.palmIcon}>
              <Image 
                source={require('@/assets/images/6e6eb815-7e35-4b9e-934d-4d9d6f43131f.png')} 
                style={styles.crystalBallImage}
                resizeMode="contain"
              />
            </View>
            
            <Button
              onPress={handleStartReading}
              style={styles.primaryButton}
              textStyle={styles.primaryButtonText}
              size="lg"
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
              <Text style={styles.featureText}>Life Line{'\n'}Analysis</Text>
            </View>
            <View style={styles.feature}>
              <Text style={styles.featureIcon}>🧠</Text>
              <Text style={styles.featureText}>Head Line{'\n'}Insights</Text>
            </View>
            <View style={styles.feature}>
              <Text style={styles.featureIcon}>❤️</Text>
              <Text style={styles.featureText}>Heart Line{'\n'}Reading</Text>
            </View>
          </View>

          {/* Ad Banner Placeholder */}
          <View style={styles.adBanner}>
            <Text style={styles.adText}>📱 Advertisement Space</Text>
            <Pressable onPress={handlePremium}>
              <Text style={styles.removeAdsText}>Remove ads with Premium →</Text>
            </Pressable>
          </View>
        </View>
      </LinearGradient>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    paddingTop: Platform.OS === 'ios' ? 10 : 20,
    paddingHorizontal: 20,
    paddingBottom: 10,
  },
  headerContent: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 24,
    fontFamily: 'PlayfairDisplay_700Bold',
    color: colors.text,
    fontWeight: 'bold',
  },
  premiumButton: {
    backgroundColor: colors.primary,
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 18,
    minHeight: 36,
    alignItems: 'center',
    justifyContent: 'center',
  },
  premiumButtonText: {
    color: colors.white,
    fontSize: 14,
    fontWeight: 'bold',
    lineHeight: 16,
    includeFontPadding: false,
  },
  content: {
    flex: 1,
    paddingHorizontal: 20,
  },
  headerSection: {
    alignItems: 'center',
    marginBottom: 30,
    paddingTop: 10,
  },
  subtitle: {
    fontSize: 18,
    fontFamily: 'OpenSans_600SemiBold',
    color: colors.textSecondary,
    textAlign: 'center',
    marginBottom: 12,
  },
  description: {
    fontSize: 16,
    fontFamily: 'OpenSans_400Regular',
    color: colors.textSecondary,
    textAlign: 'center',
    paddingHorizontal: 20,
    lineHeight: 22,
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
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.1,
    shadowRadius: 15,
    elevation: 5,
  },
  crystalBallImage: {
    width: 110,
    height: 110,
  },
  palmEmoji: {
    fontSize: 60,
  },
  primaryButton: {
    backgroundColor: colors.primary,
    paddingVertical: 18,
    paddingHorizontal: 40,
    borderRadius: 28,
    width: '100%',
    maxWidth: 320,
    marginBottom: 16,
    minHeight: 56,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.1,
    shadowRadius: 15,
    elevation: 5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  primaryButtonText: {
    fontSize: 18,
    fontFamily: 'OpenSans_700Bold',
    color: colors.white,
    textAlign: 'center',
    lineHeight: 22,
    includeFontPadding: false,
  },
  secondaryButton: {
    paddingVertical: 14,
    paddingHorizontal: 30,
    minHeight: 42,
    alignItems: 'center',
    justifyContent: 'center',
  },
  secondaryButtonText: {
    fontSize: 16,
    fontFamily: 'OpenSans_400Regular',
    color: colors.textSecondary,
    textDecorationLine: 'underline',
    lineHeight: 20,
    includeFontPadding: false,
  },
  featuresSection: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingHorizontal: 10,
    marginBottom: 20,
  },
  feature: {
    alignItems: 'center',
    flex: 1,
    paddingHorizontal: 5,
  },
  featureIcon: {
    fontSize: 24,
    marginBottom: 8,
  },
  featureText: {
    fontSize: 12,
    fontFamily: 'OpenSans_600SemiBold',
    color: colors.textSecondary,
    textAlign: 'center',
    lineHeight: 16,
  },
  adBanner: {
    backgroundColor: 'rgba(255, 255, 255, 0.8)',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.accent,
    borderStyle: 'dashed',
    marginBottom: 20,
  },
  adText: {
    fontSize: 14,
    fontFamily: 'OpenSans_400Regular',
    color: colors.textLight,
    marginBottom: 4,
  },
  removeAdsText: {
    fontSize: 12,
    fontFamily: 'OpenSans_600SemiBold',
    color: colors.primary,
  },
});
