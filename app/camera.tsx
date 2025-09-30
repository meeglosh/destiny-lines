
import React, { useState } from 'react';
import { View, Text, StyleSheet, Alert, Image, Pressable } from 'react-native';
import { router, Stack } from 'expo-router';
import * as ImagePicker from 'expo-image-picker';
import { commonStyles, colors, textStyles, buttonStyles } from '@/styles/commonStyles';
import { Button } from '@/components/button';
import { LinearGradient } from 'expo-linear-gradient';
import AdBanner from '@/components/AdBanner';

export default function CameraScreen() {
  const [selectedImage, setSelectedImage] = useState<string | null>(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);

  console.log('CameraScreen rendered');

  const requestPermissions = async () => {
    console.log('Requesting camera permissions');
    const { status } = await ImagePicker.requestCameraPermissionsAsync();
    if (status !== 'granted') {
      Alert.alert(
        'Permission Required',
        'Camera permission is needed to take photos of your palm.',
        [{ text: 'OK' }]
      );
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
        console.log('Image captured successfully');
        setSelectedImage(result.assets[0].uri);
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
        console.log('Image selected from gallery');
        setSelectedImage(result.assets[0].uri);
      }
    } catch (error) {
      console.log('Error selecting image:', error);
      Alert.alert('Error', 'Failed to select image. Please try again.');
    }
  };

  const analyzeImage = async () => {
    if (!selectedImage) return;

    console.log('Starting palm analysis');
    setIsAnalyzing(true);

    // Simulate AI analysis delay
    setTimeout(() => {
      console.log('Analysis complete, navigating to results');
      setIsAnalyzing(false);
      router.push({
        pathname: '/results',
        params: { imageUri: selectedImage }
      });
    }, 3000);
  };

  const retakePicture = () => {
    console.log('Retaking picture');
    setSelectedImage(null);
  };

  return (
    <View style={commonStyles.wrapper}>
      <Stack.Screen 
        options={{ 
          title: 'Capture Your Palm',
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
        {!selectedImage ? (
          <>
            {/* Instructions Section */}
            <View style={styles.instructionsSection}>
              <Text style={styles.title}>📸 Take a Clear Photo</Text>
              <Text style={styles.instruction}>
                For the best reading, please:
              </Text>
              <View style={styles.tipsList}>
                <Text style={styles.tip}>• Hold your palm flat and steady</Text>
                <Text style={styles.tip}>• Ensure good lighting</Text>
                <Text style={styles.tip}>• Keep your hand centered</Text>
                <Text style={styles.tip}>• Avoid shadows on your palm</Text>
              </View>
            </View>

            {/* Ad Banner */}
            <AdBanner style={styles.adBanner} />

            {/* Action Buttons */}
            <View style={styles.actionSection}>
              <Button
                onPress={takePicture}
                style={styles.primaryButton}
                textStyle={styles.primaryButtonText}
              >
                📷 Take Photo
              </Button>
              
              <Button
                onPress={selectFromGallery}
                style={styles.secondaryButton}
                textStyle={styles.secondaryButtonText}
              >
                🖼️ Choose from Gallery
              </Button>
            </View>
          </>
        ) : (
          <>
            {/* Image Preview Section */}
            <View style={styles.previewSection}>
              <Text style={styles.title}>Your Palm Photo</Text>
              <View style={styles.imageContainer}>
                <Image source={{ uri: selectedImage }} style={styles.previewImage} />
              </View>
            </View>

            {/* Analysis Actions */}
            <View style={styles.actionSection}>
              <Button
                onPress={analyzeImage}
                loading={isAnalyzing}
                disabled={isAnalyzing}
                style={styles.primaryButton}
                textStyle={styles.primaryButtonText}
              >
                {isAnalyzing ? 'Analyzing Palm...' : '🔮 Analyze Palm'}
              </Button>
              
              <Button
                onPress={retakePicture}
                disabled={isAnalyzing}
                style={styles.secondaryButton}
                textStyle={styles.secondaryButtonText}
              >
                📷 Retake Photo
              </Button>
            </View>
          </>
        )}
      </LinearGradient>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
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
  instructionsSection: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 20,
  },
  title: {
    ...textStyles.title,
    fontSize: 24,
    marginBottom: 20,
  },
  instruction: {
    ...textStyles.subtitle,
    fontSize: 18,
    marginBottom: 20,
  },
  tipsList: {
    alignItems: 'flex-start',
  },
  tip: {
    ...textStyles.body,
    marginBottom: 8,
  },
  previewSection: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  imageContainer: {
    width: 280,
    height: 280,
    borderRadius: 20,
    overflow: 'hidden',
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    ...commonStyles.shadow,
  },
  previewImage: {
    width: '100%',
    height: '100%',
    resizeMode: 'cover',
  },
  adBanner: {
    marginVertical: 20,
  },
  actionSection: {
    paddingTop: 20,
  },
  primaryButton: {
    ...buttonStyles.primary,
    marginBottom: 16,
  },
  primaryButtonText: {
    ...textStyles.buttonPrimary,
  },
  secondaryButton: {
    ...buttonStyles.secondary,
  },
  secondaryButtonText: {
    ...textStyles.buttonSecondary,
  },
});
