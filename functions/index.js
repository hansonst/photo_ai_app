const {onCall} = require('firebase-functions/v2/https');
const {setGlobalOptions} = require('firebase-functions/v2');
const {defineSecret} = require('firebase-functions/params');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

// Use NanoBanana API key
const nanoBananaApiKey = defineSecret('NANOBANANA_API_KEY');

setGlobalOptions({
  region: 'asia-southeast2',
  maxInstances: 10,
});

/**
 * Generate AI images using NanoBanana API
 * Supports: text-only, image-only, or text+image generation
 */
exports.generateImages = onCall(
  {
    timeoutSeconds: 540,
    memory: '1GiB',
    secrets: [nanoBananaApiKey],
  },
  async (request) => {
    if (!request.auth) {
      throw new Error('User must be authenticated to generate images');
    }

    const { imageUrl, prompt } = request.data;
    
    if (!imageUrl && !prompt) {
      throw new Error('Either image URL or prompt is required');
    }

    const userId = request.auth.uid;
    const apiKey = nanoBananaApiKey.value();
    
    try {
      console.log('Starting image generation for user:', userId);
      console.log('Mode:', imageUrl && prompt ? 'Image+Text' : imageUrl ? 'Image only' : 'Text only');

      const generatedImages = [];

      // Define scene prompts (used for image-only mode)
      const scenePrompts = [
        'Place this person at a beautiful tropical beach at sunset with palm trees, golden sand, and turquoise water. Professional travel photography style.',
        'Place this person in a modern city at night with illuminated skyscrapers and bright lights. Urban lifestyle photography.',
        'Place this person at a mountain peak during sunrise with stunning vistas and dramatic clouds. Epic adventure photography.',
        'Place this person in a cozy aesthetic cafe with warm lighting and modern decor. Lifestyle blogger photography.',
      ];

      // Determine prompts to use
      let promptsToGenerate = [];
      
      if (prompt && !imageUrl) {
        // Text-only mode: Use user's prompt
        promptsToGenerate = [prompt];
      } else if (imageUrl && !prompt) {
        // Image-only mode: Use all scene prompts
        promptsToGenerate = scenePrompts;
      } else if (imageUrl && prompt) {
        // Text+Image mode: Use user's prompt
        promptsToGenerate = [prompt];
      }

      // Generate images using NanoBanana
      for (const promptText of promptsToGenerate) {
        try {
          console.log(`Generating with prompt: ${promptText.substring(0, 50)}...`);
          
          const generatedImageUrl = await generateWithNanoBanana(
            apiKey,
            promptText,
            imageUrl,
            userId
          );
          
          if (generatedImageUrl) {
            generatedImages.push(generatedImageUrl);
          }
          
          // Small delay to avoid rate limits
          await new Promise(resolve => setTimeout(resolve, 2000));
        } catch (error) {
          console.error(`Error generating image:`, error.message);
          // Continue with other generations
        }
      }

      if (generatedImages.length === 0) {
        throw new Error('Failed to generate any images. Please try again.');
      }

      // Save to Firestore
      await admin.firestore()
        .collection('users')
        .doc(userId)
        .collection('generations')
        .add({
          originalImageUrl: imageUrl || null,
          userPrompt: prompt || null,
          generatedImages: generatedImages,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      console.log(`Successfully generated ${generatedImages.length} images`);

      return {
        success: true,
        generatedImages: generatedImages,
        count: generatedImages.length,
      };

    } catch (error) {
      console.error('Error in generateImages:', error);
      throw new Error('Failed to generate images: ' + error.message);
    }
  }
);

/**
 * Generate image using NanoBanana API
 */
async function generateWithNanoBanana(apiKey, promptText, imageUrl, userId) {
  try {
    const baseUrl = 'https://api.nanobananaapi.ai/api/v1/nanobanana';
    
    // Build request body based on whether we have an image
    const requestBody = {
      prompt: promptText,
      numImages: 1,
      watermark: false,
    };

    // Add image URL if provided - use NanoBanana's exact spelling (with typo)
    if (imageUrl) {
      requestBody.type = 'IMAGETOIAMGE'; // Note: API has typo - missing second 'A'
      requestBody.imageUrls = [imageUrl];
    } else {
      requestBody.type = 'TEXTTOIAMGE'; // Note: API has typo - missing second 'A'
    }
    
    console.log('Request body:', JSON.stringify(requestBody, null, 2));
    
    // Step 1: Submit generation task
    console.log('Submitting generation task to NanoBanana...');
    const generateResponse = await axios.post(
      `${baseUrl}/generate`,
      requestBody,
      {
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        timeout: 30000,
      }
    );

    console.log('NanoBanana response:', JSON.stringify(generateResponse.data, null, 2));

    if (!generateResponse.data || generateResponse.data.code !== 200) {
      throw new Error(`Generation failed: ${generateResponse.data?.msg || 'Unknown error'}`);
    }

    const taskId = generateResponse.data.data.taskId;
    console.log(`Task submitted. Task ID: ${taskId}`);

    // Step 2: Poll for completion
    const result = await waitForCompletion(apiKey, taskId, baseUrl);
    
    if (!result || !result.resultImageUrl) {
      throw new Error('No image URL in result');
    }

    console.log('Image generated successfully:', result.resultImageUrl);
    return result.resultImageUrl;

  } catch (error) {
    console.error('NanoBanana API error:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Poll NanoBanana API until task completes
 */
async function waitForCompletion(apiKey, taskId, baseUrl, maxWaitTime = 300000) {
  const startTime = Date.now();
  const pollInterval = 3000; // 3 seconds
  
  while (Date.now() - startTime < maxWaitTime) {
    try {
      const statusResponse = await axios.get(
        `${baseUrl}/record-info?taskId=${taskId}`,
        {
          headers: {
            'Authorization': `Bearer ${apiKey}`,
          },
          timeout: 10000,
        }
      );

      const status = statusResponse.data;
      
      console.log('Full status response:', JSON.stringify(status, null, 2));
      
      // Check the data object for completion status
      if (status.code === 200 && status.data) {
        const taskData = status.data;
        
        // successFlag: 0 = processing, 1 = completed, 2/3 = failed
        if (taskData.successFlag === 1 && taskData.response) {
          console.log('Generation completed successfully!');
          return taskData.response;
        } else if (taskData.successFlag === 2 || taskData.successFlag === 3) {
          throw new Error(taskData.errorMessage || 'Generation failed');
        } else if (taskData.successFlag === 0) {
          console.log('Task is still generating...');
        } else {
          console.log('Unknown status:', taskData.successFlag);
        }
      } else if (status.code !== 200) {
        throw new Error(status.msg || 'API request failed');
      }
      
      // Wait before next poll
      await new Promise(resolve => setTimeout(resolve, pollInterval));
      
    } catch (error) {
      if (error.message.includes('Generation failed')) {
        throw error;
      }
      console.error('Error polling status:', error.message);
      // Continue polling on network errors
      await new Promise(resolve => setTimeout(resolve, pollInterval));
    }
  }
  
  throw new Error('Generation timeout - exceeded maximum wait time');
}