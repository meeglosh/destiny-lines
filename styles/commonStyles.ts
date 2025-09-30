
import { StyleSheet, ViewStyle, TextStyle } from 'react-native';

export const colors = {
  primary: '#6B4423',        // Deep brown for primary actions
  secondary: '#8D6E63',      // Medium brown for secondary elements
  accent: '#D4C4A8',         // Light beige for accents
  background: '#F5F1E8',     // Very light beige background
  backgroundAlt: '#E8DCC6',  // Slightly darker beige
  text: '#5D4037',           // Dark brown text
  textSecondary: '#795548',  // Medium brown text
  textLight: '#8D6E63',      // Light brown text
  white: '#FFFFFF',
  shadow: 'rgba(0, 0, 0, 0.1)',
};

export const fonts = {
  regular: 'OpenSans_400Regular',
  semiBold: 'OpenSans_600SemiBold',
  bold: 'OpenSans_700Bold',
  displayRegular: 'PlayfairDisplay_400Regular',
  displayBold: 'PlayfairDisplay_700Bold',
};

export const buttonStyles = StyleSheet.create({
  primary: {
    backgroundColor: colors.primary,
    paddingVertical: 16,
    paddingHorizontal: 32,
    borderRadius: 25,
    boxShadow: `0px 4px 15px ${colors.shadow}`,
    elevation: 5,
  },
  secondary: {
    backgroundColor: colors.white,
    paddingVertical: 14,
    paddingHorizontal: 32,
    borderRadius: 25,
    borderWidth: 2,
    borderColor: colors.secondary,
  },
  tertiary: {
    backgroundColor: 'transparent',
    paddingVertical: 12,
    paddingHorizontal: 32,
  },
});

export const textStyles = StyleSheet.create({
  title: {
    fontSize: 28,
    fontFamily: fonts.displayBold,
    color: colors.text,
    textAlign: 'center',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 18,
    fontFamily: fonts.semiBold,
    color: colors.textSecondary,
    textAlign: 'center',
    marginBottom: 16,
  },
  body: {
    fontSize: 16,
    fontFamily: fonts.regular,
    color: colors.textSecondary,
    lineHeight: 24,
  },
  caption: {
    fontSize: 14,
    fontFamily: fonts.regular,
    color: colors.textLight,
  },
  buttonPrimary: {
    fontSize: 18,
    fontFamily: fonts.bold,
    color: colors.white,
    textAlign: 'center',
  },
  buttonSecondary: {
    fontSize: 16,
    fontFamily: fonts.semiBold,
    color: colors.primary,
    textAlign: 'center',
  },
});

export const commonStyles = StyleSheet.create({
  wrapper: {
    backgroundColor: colors.background,
    width: '100%',
    height: '100%',
  },
  container: {
    flex: 1,
    backgroundColor: colors.background,
    width: '100%',
    height: '100%',
    justifyContent: 'center',
    alignItems: 'center',
  },
  content: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    maxWidth: 800,
    width: '100%',
  },
  section: {
    width: '100%',
    alignItems: 'center',
    paddingHorizontal: 20,
  },
  buttonContainer: {
    width: '100%',
    alignItems: 'center',
    paddingHorizontal: 20,
  },
  card: {
    backgroundColor: colors.white,
    borderRadius: 15,
    padding: 20,
    marginVertical: 8,
    width: '100%',
    boxShadow: `0px 2px 10px ${colors.shadow}`,
    elevation: 3,
  },
  shadow: {
    boxShadow: `0px 4px 15px ${colors.shadow}`,
    elevation: 5,
  },
});
