
import { View, Text, StyleSheet, Alert, Image, Pressable, SafeAreaView, Platform } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import React, { useState } from 'react';
import * as ImagePicker from 'expo-image-picker';
import { router } from 'expo-router';
import { Button } from '@/components/button';
import AdBanner from '@/components/AdBanner';
import { commonStyles, colors, textStyles, buttonStyles } from '@/styles/commonStyles';
import { analyzePalmImage, validateApiKey } from '@/utils/openaiService';

export default function CameraScreen() {
  const [image, setImage] = useState<string | null>(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  console.log('📱 CameraScreen rendered');

  const requestPermissions = async () => {
    console.log('🔐 Requesting camera permissions');
    const { status } = await ImagePicker.requestCameraPermissionsAsync();
    if (status !== 'granted') {
      Alert.alert(
        'Camera Permission Required', 
        'To capture your palm photo for analysis, we need access to your camera. Please allow camera access in your device settings.',
        [{ text: 'OK' }]
      );
      return false;
    }
    return true;
  };

  const takePicture = async () => {
    console.log('📷 Taking picture');
    const hasPermission = await requestPermissions();
    if (!hasPermission) return;

    try {
      const result = await ImagePicker.launchCameraAsync({
        mediaTypes: ImagePicker.MediaTypeOptions.Images,
        allowsEditing: false,
        quality: 0.8,
      });

      if (!result.canceled && result.assets[0]) {
        console.log('✅ Image captured:', result.assets[0].uri);
        setImage(result.assets[0].uri);
      }
    } catch (error) {
      console.log('❌ Error taking picture:', error);
      Alert.alert('Error', 'Failed to take picture. Please try again.');
    }
  };

  const selectFromGallery = async () => {
    console.log('🖼️ Selecting from gallery');
    try {
      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ImagePicker.MediaTypeOptions.Images,
        allowsEditing: false,
        quality: 0.8,
      });

      if (!result.canceled && result.assets[0]) {
        console.log('✅ Image selected:', result.assets[0].uri);
        setImage(result.assets[0].uri);
      }
    } catch (error) {
      console.log('❌ Error selecting image:', error);
      Alert.alert('Error', 'Failed to select image. Please try again.');
    }
  };

  const analyzeImage = async () => {
    if (!image) {
      Alert.alert('No Image', 'Please take a photo or select one from your gallery first.');
      return;
    }

    console.log('🔮 Starting palm analysis process...');
    
    // Check if API key is configured
    if (!validateApiKey()) {
      console.log('🚀 API key validated, calling OpenAI...');
      Alert.alert(
        'OpenAI API Key Required',
        'To get personalized palm readings, you need to configure your OpenAI API key. For now, you\'ll receive a sample reading.',
        [
          { 
            text: 'Continue with Sample', 
            onPress: () => proceedWithAnalysis()
          },
          { text: 'Cancel', style: 'cancel' }
        ]
      );
      return;
    }

    await proceedWithAnalysis();
  };

  const proceedWithAnalysis = async () => {
    console.log('🚀 API key validated, calling OpenAI...');
    setIsAnalyzing(true);

    try {
      // Call OpenAI API to analyze the palm
      const palmReading = await analyzePalmImage(image!);
      
      console.log('✅ Palm analysis complete, navigating to results');
      
      // Navigate to results with the reading data
      router.push({
        pathname: '/results',
        params: { 
          imageUri: image,
          reading: JSON.stringify(palmReading)
        }
      });
    } catch (error) {
      console.log('❌ Error analyzing palm:', error);
      Alert.alert(
        'Analysis Failed', 
        'Unable to analyze your palm at the moment. Please check your internet connection and try again.',
        [{ text: 'OK' }]
      );
    } finally {
      setIsAnalyzing(false);
    }
  };

  const retakePicture = () => {
    console.log('🔄 Retaking picture');
    setImage(null);
  };

  return (
    <SafeAreaView style={commonStyles.wrapper}>
      <LinearGradient
        colors={['#F5F1E8', '#E8DCC6', '#D4C4A8']}
        style={styles.container}
      >
        <View style={styles.content}>
          {/* Instructions */}
          <View style={styles.instructionsSection}>
            <Text style={styles.title}>📸 Capture Your Palm</Text>
            <Text style={styles.instructions}>
              For the best reading, ensure your palm is well-lit and clearly visible. 
              Hold your hand steady and capture a clear image of your entire palm.
            </Text>
          </View>

          {/* Image Preview */}
          <View style={styles.imageSection}>
            {image ? (
              <View style={styles.imageContainer}>
                <Image source={{ uri: image }} style={styles.palmImage} />
                <Pressable onPress={retakePicture} style={styles.retakeButton}>
                  <Text style={styles.retakeButtonText}>Retake Photo</Text>
                </Pressable>
              </View>
            ) : (
              <View style={styles.placeholderContainer}>
                <View style={styles.placeholder}>
                  <Text style={styles.placeholderEmoji}>✋</Text>
                  <Text style={styles.placeholderText}>Your palm photo will appear here</Text>
                </View>
              </View>
            )}
          </View>

          {/* Action Buttons */}
          <View style={styles.buttonSection}>
            {!image ? (
              <>
                <Button
                  onPress={takePicture}
                  style={styles.primaryButton}
                  textStyle={styles.primaryButtonText}
                  size="lg"
                >
                  📷 Take Photo
                </Button>
                
                <Button
                  onPress={selectFromGallery}
                  style={styles.secondaryButton}
                  textStyle={styles.secondaryButtonText}
                  size="md"
                  variant="outline"
                >
                  🖼️ Choose from Gallery
                </Button>
              </>
            ) : (
              <Button
                onPress={analyzeImage}
                loading={isAnalyzing}
                disabled={isAnalyzing}
                style={styles.primaryButton}
                textStyle={styles.primaryButtonText}
                size="lg"
              >
                {isAnalyzing ? '🔮 Analyzing Palm...' : '✨ Get My Reading'}
              </Button>
            )}
          </View>

          {/* Ad Banner */}
          <AdBanner style={styles.adBanner} showRemoveAds={true} />
        </View>
      </LinearGradient>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  content: {
    flex: 1,
    paddingHorizontal: 20,
    paddingTop: 20,
    paddingBottom: 20,
  },
  instructionsSection: {
    alignItems: 'center',
    marginBottom: 24,
    paddingHorizontal: 10,
  },
  title: {
    fontSize: 24,
    fontFamily: 'PlayfairDisplay_700Bold',
    color: colors.text,
    textAlign: 'center',
    marginBottom: 12,
  },
  instructions: {
    fontSize: 16,
    fontFamily: 'OpenSans_400Regular',
    color: colors.textSecondary,
    textAlign: 'center',
    lineHeight: 22,
    paddingHorizontal: 10,
  },
  imageSection: {
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 24,
    paddingVertical: 16,
  },
  imageContainer: {
    alignItems: 'center',
  },
  palmImage: {
    width: 200,
    height: 240,
    borderRadius: 16,
    marginBottom: 12,
    borderWidth: 3,
    borderColor: colors.white,
    resizeMode: 'contain',
  },
  retakeButton: {
    paddingVertical: 8,
    paddingHorizontal: 16,
    minHeight: 36,
    alignItems: 'center',
    justifyContent: 'center',
  },
  retakeButtonText: {
    fontSize: 16,
    fontFamily: 'OpenSans_600SemiBold',
    color: colors.primary,
    textDecorationLine: 'underline',
    lineHeight: 20,
    includeFontPadding: false,
  },
  placeholderContainer: {
    width: 200,
    height: 240,
    justifyContent: 'center',
    alignItems: 'center',
  },
  placeholder: {
    width: '100%',
    height: '100%',
    borderRadius: 16,
    borderWidth: 2,
    borderColor: colors.accent,
    borderStyle: 'dashed',
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
  },
  placeholderEmoji: {
    fontSize: 48,
    marginBottom: 12,
  },
  placeholderText: {
    fontSize: 14,
    fontFamily: 'OpenSans_400Regular',
    color: colors.textSecondary,
    textAlign: 'center',
    paddingHorizontal: 16,
    lineHeight: 18,
  },
  buttonSection: {
    gap: 12,
    paddingHorizontal: 10,
    marginBottom: 16,
  },
  primaryButton: {
    backgroundColor: colors.primary,
    paddingVertical: 16,
    paddingHorizontal: 32,
    borderRadius: 28,
    minHeight: 52,
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
    fontSize: 17,
    fontFamily: 'OpenSans_700Bold',
    color: colors.white,
    textAlign: 'center',
    lineHeight: 21,
    includeFontPadding: false,
  },
  secondaryButton: {
    backgroundColor: colors.white,
    paddingVertical: 14,
    paddingHorizontal: 32,
    borderRadius: 28,
    borderWidth: 2,
    borderColor: colors.secondary,
    minHeight: 48,
    alignItems: 'center',
    justifyContent: 'center',
  },
  secondaryButtonText: {
    fontSize: 16,
    fontFamily: 'OpenSans_600SemiBold',
    color: colors.primary,
    textAlign: 'center',
    lineHeight: 20,
    includeFontPadding: false,
  },
  adBanner: {
    marginTop: 8,
  },
});
