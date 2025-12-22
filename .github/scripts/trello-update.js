#!/usr/bin/env node

const https = require('https');

const TRELLO_API_KEY = process.env.TRELLO_API_KEY;
const TRELLO_TOKEN = process.env.TRELLO_TOKEN;
const TRELLO_BOARD_ID = process.env.TRELLO_BOARD_ID;
const TRELLO_TODO_LIST_ID = process.env.TRELLO_TODO_LIST_ID; // Plan
const TRELLO_INPROGRESS_LIST_ID = process.env.TRELLO_INPROGRESS_LIST_ID; // In-Progress
const TRELLO_READY_LIST_ID = process.env.TRELLO_READY_LIST_ID; // Ready to Ship
const TRELLO_DEPLOYED_LIST_ID = process.env.TRELLO_DEPLOYED_LIST_ID || process.env.TRELLO_DONE_LIST_ID; // Deployed
const CARD_ID = process.env.CARD_ID;

const BUILD_STATUS = process.env.BUILD_STATUS; // 'plan' | 'inprogress' | 'ready' | 'deployed' | 'failure'
const TASK_DESCRIPTION = process.env.TASK_DESCRIPTION;
const GITHUB_SHA = process.env.GITHUB_SHA;
const GITHUB_REF = process.env.GITHUB_REF;
const GITHUB_ACTOR = process.env.GITHUB_ACTOR;

const branchName = GITHUB_REF.split('/').pop();
const shortSha = GITHUB_SHA.substring(0, 7);
const CARD_NAME = TASK_DESCRIPTION
  ? `${TASK_DESCRIPTION} | ${branchName}@${shortSha}`
  : `Build #${shortSha} - ${branchName}`;
const CARD_DESC = `Build Status: ${BUILD_STATUS.toUpperCase()}\nCommit: ${GITHUB_SHA}\nBranch: ${GITHUB_REF}\nActor: ${GITHUB_ACTOR}\nTimestamp: ${new Date().toISOString()}${TASK_DESCRIPTION ? `\nTask: ${TASK_DESCRIPTION}` : ''}`;

function makeRequest(method, path, body = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.trello.com',
      path,
      method,
      headers: {
        'Content-Type': 'application/json',
      },
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        resolve({
          status: res.statusCode,
          data: data ? JSON.parse(data) : null,
        });
      });
    });

    req.on('error', reject);
    if (body) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
}

async function findExistingCard() {
  if (CARD_ID) {
    try {
      const response = await makeRequest(
        'GET',
        `/1/cards/${CARD_ID}?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}`
      );
      if (response.status === 200 && response.data) {
        return response.data;
      }
    } catch (error) {
      console.error('Error fetching card by CARD_ID:', error);
    }
  }

  try {
    const response = await makeRequest(
      'GET',
      `/1/boards/${TRELLO_BOARD_ID}/cards?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}`
    );
    const cards = response.data || [];
    return cards.find((card) => card.name.includes(GITHUB_SHA.substring(0, 7)));
  } catch (error) {
    console.error('Error finding card:', error);
    return null;
  }
}

async function createCard(listId) {
  try {
    const response = await makeRequest('POST', `/1/cards?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}`, {
      name: CARD_NAME,
      desc: CARD_DESC,
      idList: listId,
      labels: BUILD_STATUS === 'success' ? ['green'] : ['red'],
    });
    console.log('Card created:', response.data?.id);
    return response.data?.id;
  } catch (error) {
    console.error('Error creating card:', error);
    throw error;
  }
}

async function updateCard(cardId, listId) {
  try {
    const response = await makeRequest('PUT', `/1/cards/${cardId}?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}`, {
      idList: listId,
      desc: CARD_DESC,
      labels: BUILD_STATUS === 'success' ? ['green'] : ['red'],
    });
    console.log('Card updated:', response.data?.id);
    return response.data?.id;
  } catch (error) {
    console.error('Error updating card:', error);
    throw error;
  }
}

async function main() {
  try {
    console.log(`Processing build status: ${BUILD_STATUS}`);

    // Determine target list
    let targetListId;
    switch (BUILD_STATUS) {
      case 'plan':
        targetListId = TRELLO_TODO_LIST_ID;
        break;
      case 'inprogress':
        targetListId = TRELLO_INPROGRESS_LIST_ID;
        break;
      case 'ready':
        targetListId = TRELLO_READY_LIST_ID || TRELLO_INPROGRESS_LIST_ID;
        break;
      case 'deployed':
        targetListId = TRELLO_DEPLOYED_LIST_ID;
        break;
      case 'failure':
      default:
        targetListId = TRELLO_INPROGRESS_LIST_ID;
        break;
    }

    // Find existing card or create new one
    const existingCard = await findExistingCard();

    if (existingCard) {
      console.log(`Found existing card: ${existingCard.id}`);
      await updateCard(existingCard.id, targetListId);
    } else {
      console.log('Creating new card...');
      await createCard(targetListId);
    }

    console.log(`Build ${BUILD_STATUS} - Trello card updated`);
    process.exit(0);
  } catch (error) {
    console.error('Fatal error:', error);
    process.exit(1);
  }
}

main();
