
import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Pressable, Alert } from 'react-native';
import { router, Stack } from 'expo-router';
import { commonStyles, colors, textStyles, buttonStyles } from '@/styles/commonStyles';
import { Button } from '@/components/button';
import { LinearGradient } from 'expo-linear-gradient';

const premiumFeatures = [
  {
    icon: '🚫',
    title: 'Ad-Free Experience',
    description: 'Enjoy uninterrupted palm readings without any advertisements'
  },
  {
    icon: '💾',
    title: 'Unlimited History',
    description: 'Save and access all your palm readings with no limits'
  },
  {
    icon: '🔮',
    title: 'Advanced Readings',
    description: 'Get more detailed and comprehensive palm analysis'
  },
  {
    icon: '📤',
    title: 'Enhanced Sharing',
    description: 'Share readings with custom formatting and images'
  },
  {
    icon: '🎨',
    title: 'Premium Themes',
    description: 'Access exclusive app themes and customization options'
  },
  {
    icon: '⚡',
    title: 'Priority Support',
    description: 'Get faster customer support and feature requests'
  }
];

export default function PremiumScreen() {
  const [isPurchasing, setIsPurchasing] = useState(false);

  console.log('PremiumScreen rendered');

  const handlePurchase = async () => {
    console.log('Starting premium purchase');
    setIsPurchasing(true);

    // Simulate purchase process
    setTimeout(() => {
      setIsPurchasing(false);
      Alert.alert(
        'Purchase Successful! 🎉',
        'Welcome to Destiny Lines Premium! You now have access to all premium features.',
        [
          {
            text: 'Continue',
            onPress: () => router.push('/')
          }
        ]
      );
    }, 2000);
  };

  const restorePurchases = () => {
    console.log('Restoring purchases');
    Alert.alert(
      'Restore Purchases',
      'No previous purchases found for this account.',
      [{ text: 'OK' }]
    );
  };

  return (
    <View style={commonStyles.wrapper}>
      <Stack.Screen 
        options={{ 
          title: 'Destiny Lines Premium',
          headerStyle: { backgroundColor: colors.background },
          headerTintColor: colors.text,
          headerLeft: () => (
            <Pressable onPress={() => router.back()} style={styles.backButton}>
              <Text style={styles.backButtonText}>← Back</Text>
            </Pressable>
          ),
        }} 
      />
      
      <LinearGradient
        colors={['#F5F1E8', '#E8DCC6', '#D4C4A8']}
        style={styles.container}
      >
        <ScrollView 
          style={styles.scrollView}
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          {/* Header */}
          <View style={styles.header}>
            <Text style={styles.premiumBadge}>✨ PREMIUM ✨</Text>
            <Text style={styles.title}>Unlock Your Full Destiny</Text>
            <Text style={styles.subtitle}>
              Get the complete palm reading experience
            </Text>
          </View>

          {/* Pricing */}
          <View style={styles.pricingCard}>
            <Text style={styles.price}>$2.99</Text>
            <Text style={styles.priceSubtext}>One-time purchase</Text>
            <Text style={styles.priceDescription}>
              Lifetime access to all premium features
            </Text>
          </View>

          {/* Features */}
          <View style={styles.featuresContainer}>
            <Text style={styles.featuresTitle}>Premium Features</Text>
            {premiumFeatures.map((feature, index) => (
              <View key={index} style={styles.featureItem}>
                <Text style={styles.featureIcon}>{feature.icon}</Text>
                <View style={styles.featureContent}>
                  <Text style={styles.featureTitle}>{feature.title}</Text>
                  <Text style={styles.featureDescription}>{feature.description}</Text>
                </View>
              </View>
            ))}
          </View>

          {/* Action Buttons */}
          <View style={styles.actionSection}>
            <Button
              onPress={handlePurchase}
              loading={isPurchasing}
              disabled={isPurchasing}
              style={styles.purchaseButton}
              textStyle={styles.purchaseButtonText}
            >
              {isPurchasing ? 'Processing...' : '🔮 Upgrade to Premium'}
            </Button>
            
            <Pressable onPress={restorePurchases} style={styles.restoreButton}>
              <Text style={styles.restoreButtonText}>Restore Purchases</Text>
            </Pressable>
          </View>

          {/* Terms */}
          <View style={styles.termsSection}>
            <Text style={styles.termsText}>
              By purchasing, you agree to our Terms of Service and Privacy Policy.
              This is a one-time purchase with lifetime access to premium features.
            </Text>
          </View>
        </ScrollView>
      </LinearGradient>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: 20,
    paddingTop: 20,
    paddingBottom: 40,
  },
  backButton: {
    paddingHorizontal: 16,
    paddingVertical: 8,
  },
  backButtonText: {
    color: colors.text,
    fontSize: 16,
    fontWeight: '500',
  },
  header: {
    alignItems: 'center',
    marginBottom: 30,
  },
  premiumBadge: {
    fontSize: 16,
    fontWeight: 'bold',
    color: colors.primary,
    backgroundColor: 'rgba(255, 255, 255, 0.8)',
    paddingHorizontal: 16,
    paddingVertical: 6,
    borderRadius: 20,
    marginBottom: 16,
  },
  title: {
    ...textStyles.title,
    fontSize: 32,
    marginBottom: 8,
  },
  subtitle: {
    ...textStyles.subtitle,
    fontSize: 18,
  },
  pricingCard: {
    backgroundColor: 'rgba(255, 255, 255, 0.9)',
    borderRadius: 20,
    padding: 30,
    alignItems: 'center',
    marginBottom: 30,
    boxShadow: '0px 4px 20px rgba(0, 0, 0, 0.1)',
    elevation: 5,
  },
  price: {
    fontSize: 48,
    fontWeight: 'bold',
    color: colors.primary,
    marginBottom: 8,
  },
  priceSubtext: {
    fontSize: 18,
    color: colors.textSecondary,
    marginBottom: 8,
  },
  priceDescription: {
    fontSize: 14,
    color: colors.textLight,
    textAlign: 'center',
  },
  featuresContainer: {
    marginBottom: 30,
  },
  featuresTitle: {
    fontSize: 22,
    fontWeight: 'bold',
    color: colors.text,
    textAlign: 'center',
    marginBottom: 20,
  },
  featureItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    backgroundColor: 'rgba(255, 255, 255, 0.7)',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
  },
  featureIcon: {
    fontSize: 24,
    marginRight: 16,
    marginTop: 2,
  },
  featureContent: {
    flex: 1,
  },
  featureTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: colors.text,
    marginBottom: 4,
  },
  featureDescription: {
    fontSize: 14,
    color: colors.textSecondary,
    lineHeight: 20,
  },
  actionSection: {
    alignItems: 'center',
    marginBottom: 30,
  },
  purchaseButton: {
    ...buttonStyles.primary,
    width: '100%',
    marginBottom: 16,
  },
  purchaseButtonText: {
    ...textStyles.buttonPrimary,
    fontSize: 20,
  },
  restoreButton: {
    paddingVertical: 12,
    paddingHorizontal: 20,
  },
  restoreButtonText: {
    fontSize: 16,
    color: colors.textLight,
    textDecorationLine: 'underline',
  },
  termsSection: {
    paddingHorizontal: 20,
  },
  termsText: {
    fontSize: 12,
    color: colors.textLight,
    textAlign: 'center',
    lineHeight: 18,
  },
});
