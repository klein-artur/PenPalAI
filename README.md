# PenPalAI

PenPalAI is a proof-of-concept package written in Swift for a chatbot based on GPT-4. It's designed to progressively learn more about its users, similar to a pen pal.

## How It Works

### The Chatbot

PenPal AI leverages [SwiftGPT](https://github.com/klein-artur/SwiftGPT), a lightweight wrapper for OpenAI's chat completion API, to facilitate communication with GPT-4. The utilization of GPT-4 is crucial as its function-calling capability is vital for the PenPalAI's functionality.

### The Memory

The core of the memory functionality lies in GPT-4's ability to invoke functions when deemed necessary. The model has access to three primary functions for managing its memory:

1. `saveMemory(snippet, isKeyMemory)`: Saves a memory snippet to the database.
    - `snippet` is a piece of text that the model wishes to remember. For example, upon learning that the chat partner enjoys rock music, it might save the snippet "user likes rock music".
    - `isKeyMemory` is a boolean indicating whether the snippet is critical for future interactions. For instance, if the model discovers the user's preferred language, it will store this as a key memory since it's significant to recognize at the start of every conversation. Currently, the ten most recent key memories are injected into the system messages at the beginning of a chat.

2. `getMemory(searchString)`: Retrieves memories that match a specified `searchString` and returns them as a list of comma-separated information.
    - `searchString` is a text snippet that the model uses to look up information. For example, to find out a user's favorite music genre, it might search for "user's favorite music genre". Memories are located using the cosine similarity of their embeddings.

3. `replaceMemory(oldSnippet, newSnippet)`: Allows the model to update incorrect information with the correct one.
    - `oldSnippet`: The model places the incorrect snippet here. The text is found using an exact match, so the model provides the exact value it previously obtained. The incorrect value is then replaced with the new information.
    
Through these functions, the model can autonomously manage its memory, retaining what it deems valuable. If it requires information, such as the user's favorite music genre, it can look it up; if it's not available, the model can ask the user, save their response, and utilize this data in subsequent conversations.

### Embeddings

Embeddings are produced using OpenAI's embedding API.

### The Database

Currently, SQLite is employed as the database. Although not ideal, since a vector-based database would be preferable for fetching by embedding, it suffices for the proof of concept. The process involves fetching all memories and then calculating their cosine similarity, which, while not the most efficient, is effective for the time being.

## How to Use

Import the package and instantiate a new `PenPalAI` object. The initializer requires two parameters:

1. `pal`: The path to the database. A new database will be created if it does not already exist.
2. `apiKey`: The API key for OpenAI's chat completion API.

```swift
import PenPalAI

let myPenPal = PenPalAI(pal: thePathToTheDatabase, apiKey: yourApiKey)

// You can now converse with your PenPal
let answer = try await myPenPal.send(message: userInput)

```

A PenPalAI object maintains the chat history and state. However, creating a new instance of PenPalAI will start a fresh chat. If the same database is utilized, the new instance will have access to the accumulated knowledge of the previous instances, but since the context is reset, the conversation will start anew.

