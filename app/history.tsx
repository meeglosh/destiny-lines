
import React from 'react';
import { View, Text, StyleSheet, ScrollView, Pressable } from 'react-native';
import { router, Stack } from 'expo-router';
import { commonStyles, colors } from '@/styles/commonStyles';
import { Button } from '@/components/button';
import { LinearGradient } from 'expo-linear-gradient';

// Mock history data
const mockHistory = [
  {
    id: '1',
    date: '2024-01-15',
    time: '2:30 PM',
    summary: 'Resilient and thoughtful palm with strong life line',
    emoji: '🌟'
  },
  {
    id: '2',
    date: '2024-01-10',
    time: '11:45 AM',
    summary: 'Creative air hand with excellent communication traits',
    emoji: '✋'
  },
  {
    id: '3',
    date: '2024-01-05',
    time: '4:15 PM',
    summary: 'Strong heart line indicating deep emotional connections',
    emoji: '❤️'
  }
];

export default function HistoryScreen() {
  console.log('HistoryScreen rendered');

  const viewReading = (readingId: string) => {
    console.log('Viewing reading:', readingId);
    router.push('/results');
  };

  const getNewReading = () => {
    console.log('Getting new reading from history');
    router.push('/camera');
  };

  return (
    <View style={commonStyles.wrapper}>
      <Stack.Screen 
        options={{ 
          title: 'Reading History',
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
            <Text style={styles.title}>📚 Your Palm Readings</Text>
            <Text style={styles.subtitle}>
              {mockHistory.length} reading{mockHistory.length !== 1 ? 's' : ''} saved
            </Text>
          </View>

          {/* History List */}
          {mockHistory.length > 0 ? (
            <View style={styles.historyContainer}>
              {mockHistory.map((reading) => (
                <Pressable
                  key={reading.id}
                  style={styles.historyCard}
                  onPress={() => viewReading(reading.id)}
                >
                  <View style={styles.cardHeader}>
                    <Text style={styles.cardEmoji}>{reading.emoji}</Text>
                    <View style={styles.cardInfo}>
                      <Text style={styles.cardDate}>{reading.date}</Text>
                      <Text style={styles.cardTime}>{reading.time}</Text>
                    </View>
                    <Text style={styles.viewButton}>View →</Text>
                  </View>
                  <Text style={styles.cardSummary}>{reading.summary}</Text>
                </Pressable>
              ))}
            </View>
          ) : (
            <View style={styles.emptyState}>
              <Text style={styles.emptyIcon}>🔮</Text>
              <Text style={styles.emptyTitle}>No Readings Yet</Text>
              <Text style={styles.emptyText}>
                Start your first palm reading to see your destiny unfold
              </Text>
            </View>
          )}

          {/* Action Button */}
          <View style={styles.actionSection}>
            <Button
              onPress={getNewReading}
              style={styles.primaryButton}
              textStyle={styles.primaryButtonText}
            >
              ✨ New Palm Reading
            </Button>
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
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#5D4037',
    marginBottom: 8,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 16,
    color: '#8D6E63',
    textAlign: 'center',
  },
  historyContainer: {
    marginBottom: 30,
  },
  historyCard: {
    backgroundColor: 'rgba(255, 255, 255, 0.7)',
    borderRadius: 15,
    padding: 20,
    marginBottom: 16,
    boxShadow: '0px 2px 10px rgba(0, 0, 0, 0.1)',
    elevation: 3,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  cardEmoji: {
    fontSize: 24,
    marginRight: 12,
  },
  cardInfo: {
    flex: 1,
  },
  cardDate: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#5D4037',
  },
  cardTime: {
    fontSize: 14,
    color: '#8D6E63',
    marginTop: 2,
  },
  viewButton: {
    fontSize: 16,
    color: '#6B4423',
    fontWeight: '600',
  },
  cardSummary: {
    fontSize: 15,
    color: '#6D4C41',
    lineHeight: 22,
  },
  emptyState: {
    alignItems: 'center',
    paddingVertical: 60,
  },
  emptyIcon: {
    fontSize: 60,
    marginBottom: 20,
  },
  emptyTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#5D4037',
    marginBottom: 12,
    textAlign: 'center',
  },
  emptyText: {
    fontSize: 16,
    color: '#8D6E63',
    textAlign: 'center',
    lineHeight: 24,
    paddingHorizontal: 40,
  },
  actionSection: {
    paddingTop: 20,
  },
  primaryButton: {
    backgroundColor: '#6B4423',
    paddingVertical: 16,
    paddingHorizontal: 40,
    borderRadius: 25,
    boxShadow: '0px 4px 15px rgba(0, 0, 0, 0.2)',
    elevation: 5,
  },
  primaryButtonText: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: 'bold',
    textAlign: 'center',
  },
});
