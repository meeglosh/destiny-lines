
import { View, Text, StyleSheet, Alert, Image, Pressable, SafeAreaView, Platform } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import React, { useState } from 'react';
import * as ImagePicker from 'expo-image-picker';
import { router } from 'expo-router';
import { Button } from '@/components/button';
import AdBanner from '@/components/AdBanner';
import { commonStyles, colors, textStyles, buttonStyles } from '@/styles/commonStyles';

export default function CameraScreen() {
  const [image, setImage] = useState<string | null>(null);
  console.log('CameraScreen rendered');

  const requestPermissions = async () => {
    console.log('Requesting camera permissions');
    const { status } = await ImagePicker.requestCameraPermissionsAsync();
    if (status !== 'granted') {
      Alert.alert('Permission needed', 'Camera permission is required to take photos.');
      return false;
    }
    return true;
  };

  const takePicture = async () => {
    console.log('Taking picture');
    const hasPermission = await requestPermissions();
    if (!hasPermission) return;

    try {
      const result = await ImagePicker.launchCameraAsync({
        mediaTypes: ImagePicker.MediaTypeOptions.Images,
        allowsEditing: true,
        aspect: [1, 1],
        quality: 0.8,
      });

      if (!result.canceled && result.assets[0]) {
        console.log('Image captured:', result.assets[0].uri);
        setImage(result.assets[0].uri);
      }
    } catch (error) {
      console.log('Error taking picture:', error);
      Alert.alert('Error', 'Failed to take picture. Please try again.');
    }
  };

  const selectFromGallery = async () => {
    console.log('Selecting from gallery');
    try {
      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ImagePicker.MediaTypeOptions.Images,
        allowsEditing: true,
        aspect: [1, 1],
        quality: 0.8,
      });

      if (!result.canceled && result.assets[0]) {
        console.log('Image selected:', result.assets[0].uri);
        setImage(result.assets[0].uri);
      }
    } catch (error) {
      console.log('Error selecting image:', error);
      Alert.alert('Error', 'Failed to select image. Please try again.');
    }
  };

  const analyzeImage = () => {
    if (!image) {
      Alert.alert('No Image', 'Please take a photo or select one from your gallery first.');
      return;
    }
    console.log('Analyzing image:', image);
    router.push({
      pathname: '/results',
      params: { imageUri: image }
    });
  };

  const retakePicture = () => {
    console.log('Retaking picture');
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
              Hold your hand steady and capture a clear image.
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
                style={styles.primaryButton}
                textStyle={styles.primaryButtonText}
                size="lg"
              >
                ✨ Get My Reading
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
    marginBottom: 30,
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
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 30,
  },
  imageContainer: {
    alignItems: 'center',
  },
  palmImage: {
    width: 250,
    height: 250,
    borderRadius: 20,
    marginBottom: 16,
    borderWidth: 3,
    borderColor: colors.white,
  },
  retakeButton: {
    paddingVertical: 10,
    paddingHorizontal: 20,
    minHeight: 40,
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
    width: 250,
    height: 250,
    justifyContent: 'center',
    alignItems: 'center',
  },
  placeholder: {
    width: '100%',
    height: '100%',
    borderRadius: 20,
    borderWidth: 2,
    borderColor: colors.accent,
    borderStyle: 'dashed',
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
  },
  placeholderEmoji: {
    fontSize: 60,
    marginBottom: 16,
  },
  placeholderText: {
    fontSize: 16,
    fontFamily: 'OpenSans_400Regular',
    color: colors.textSecondary,
    textAlign: 'center',
    paddingHorizontal: 20,
  },
  buttonSection: {
    gap: 16,
  },
  primaryButton: {
    backgroundColor: colors.primary,
    paddingVertical: 18,
    paddingHorizontal: 40,
    borderRadius: 28,
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
    backgroundColor: colors.white,
    paddingVertical: 16,
    paddingHorizontal: 40,
    borderRadius: 28,
    borderWidth: 2,
    borderColor: colors.secondary,
    minHeight: 52,
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
    marginTop: 20,
  },
});
