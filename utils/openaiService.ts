
import * as FileSystem from 'expo-file-system';

interface PalmReading {
  lifeLine: {
    icon: string;
    title: string;
    content: string;
  };
  headLine: {
    icon: string;
    title: string;
    content: string;
  };
  heartLine: {
    icon: string;
    title: string;
    content: string;
  };
  handShape: {
    icon: string;
    title: string;
    content: string;
  };
  overall: {
    icon: string;
    title: string;
    content: string;
  };
}

// You'll need to set your OpenAI API key here
const OPENAI_API_KEY = 'YOUR_OPENAI_API_KEY_HERE';
const OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions';

export async function analyzePalmImage(imageUri: string): Promise<PalmReading> {
  console.log('Starting palm analysis for image:', imageUri);
  
  try {
    // Convert image to base64
    const base64Image = await FileSystem.readAsStringAsync(imageUri, {
      encoding: 'base64',
    });
    
    console.log('Image converted to base64, length:', base64Image.length);

    // Prepare the prompt for palm reading
    const prompt = `You are an expert palm reader. Analyze this palm image and provide a detailed reading in the exact format below. Be mystical but positive, and make the reading feel personal and insightful.

Please respond with ONLY a JSON object in this exact format:
{
  "lifeLine": {
    "icon": "🌿",
    "title": "Life Line",
    "content": "Your detailed life line reading here..."
  },
  "headLine": {
    "icon": "🧠", 
    "title": "Head Line",
    "content": "Your detailed head line reading here..."
  },
  "heartLine": {
    "icon": "❤️",
    "title": "Heart Line", 
    "content": "Your detailed heart line reading here..."
  },
  "handShape": {
    "icon": "✋",
    "title": "Shape of the Hand",
    "content": "Your detailed hand shape reading here..."
  },
  "overall": {
    "icon": "🌟",
    "title": "Overall Reading",
    "content": "Your overall palm reading summary here..."
  }
}

Make each section 2-3 sentences long, personal, and insightful. Focus on positive traits and potential.`;

    // Make API call to OpenAI
    const response = await fetch(OPENAI_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
      },
      body: JSON.stringify({
        model: 'gpt-4o',
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: prompt,
              },
              {
                type: 'image_url',
                image_url: {
                  url: `data:image/jpeg;base64,${base64Image}`,
                  detail: 'high'
                },
              },
            ],
          },
        ],
        max_tokens: 1000,
        temperature: 0.7,
      }),
    });

    console.log('OpenAI API response status:', response.status);

    if (!response.ok) {
      const errorText = await response.text();
      console.log('OpenAI API error:', errorText);
      throw new Error(`OpenAI API error: ${response.status} - ${errorText}`);
    }

    const data = await response.json();
    console.log('OpenAI API response received');

    // Parse the response
    const content = data.choices[0]?.message?.content;
    if (!content) {
      throw new Error('No content in OpenAI response');
    }

    console.log('Raw OpenAI response:', content);

    // Try to parse the JSON response
    let palmReading: PalmReading;
    try {
      // Clean the response in case there are markdown code blocks
      const cleanedContent = content.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
      palmReading = JSON.parse(cleanedContent);
    } catch (parseError) {
      console.log('Error parsing OpenAI response as JSON:', parseError);
      console.log('Content that failed to parse:', content);
      
      // Fallback to a default reading if parsing fails
      palmReading = getDefaultReading();
    }

    console.log('Palm reading analysis complete');
    return palmReading;

  } catch (error) {
    console.log('Error in analyzePalmImage:', error);
    
    // Return a default reading if the API call fails
    return getDefaultReading();
  }
}

function getDefaultReading(): PalmReading {
  console.log('Using default palm reading');
  return {
    lifeLine: {
      icon: '🌿',
      title: 'Life Line',
      content: 'Your life line shows remarkable strength and vitality. You possess natural resilience and the ability to overcome challenges with grace. Your energy flows steadily, suggesting a balanced approach to life\'s adventures.'
    },
    headLine: {
      icon: '🧠',
      title: 'Head Line',
      content: 'Your head line reveals a sharp, analytical mind with excellent problem-solving abilities. You think before you act and have a natural talent for seeing the bigger picture. Your decisions are well-considered and thoughtful.'
    },
    heartLine: {
      icon: '❤️',
      title: 'Heart Line',
      content: 'Your heart line indicates a warm, caring nature with deep emotional intelligence. You form meaningful connections and value loyalty in relationships. Your capacity for love and empathy is one of your greatest strengths.'
    },
    handShape: {
      icon: '✋',
      title: 'Shape of the Hand',
      content: 'Your hand shape suggests a perfect balance of creativity and practicality. You have the ability to turn ideas into reality and possess both artistic sensibility and logical thinking. This combination makes you uniquely capable.'
    },
    overall: {
      icon: '🌟',
      title: 'Overall Reading',
      content: 'Your palm reveals someone with tremendous potential and inner strength. You have the rare combination of wisdom, creativity, and determination. Trust in your abilities - the universe has great things in store for you.'
    }
  };
}

export function validateApiKey(): boolean {
  return OPENAI_API_KEY !== 'YOUR_OPENAI_API_KEY_HERE' && OPENAI_API_KEY.length > 0;
}
