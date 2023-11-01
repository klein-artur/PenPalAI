//
//  File.swift
//  
//
//  Created by Artur Hellmann on 30.10.23.
//

import Foundation

enum Constants {
    enum System {
        enum Functions {
            enum GetMemory {
                static let name = "get_memory"
                static let description = "Returns an information from the long term memory by searching by similarity. Use this function to get information before asking the user."
                static let searchTextParameterName = "search_text"
                static let searchTextParameterDescription = "The information to search for in english language. Will be searched by similarity with embeddings. Multiple fitting strings will be comma separated."
            }
            enum SaveMemory {
                static let name = "save_memory"
                static let description = "Saves an information to the long term memory. Use this function to save information you think is worth to keep. For example you can save preferences of the user."
                static let infoParameterName = "information"
                static let infoParameterDescription = "The information to save in english language. For example \"The user likes chocolate\"."
                static let isKeyParameterName = "is_key"
                static let isKeyParameterDescription = "Pass true here if you think this is an information that is very important to know at the beginning of the next conversation before any message is sent. For example the preferred language you have to answer in or if he wants to talk formal or informal. Information that you can fetch after a question is not considered as important."
            } 
            enum ReplaceMemory {
                static let name = "replace_memory"
                static let description = "Replaces an information in the long term memory. Use this function to replace information that is wrong. You can also replace an information that you were given at the start, not only fetched ones."
                static let oldInfoParameterName = "old_information"
                static let oldInfoParameterDescription = "The information to replace, take it as you got it because the database is filtered by the string. This can also be one of the prefetched informations you will get at the start of the conversation."
                static let newInfoParameterName = "new_information"
                static let newInfoParameterDescription = "The new information in english language."
            }
        }
        static let saveMemoryFunctionName = "save_memory"
        static let replaceMemoryFunctionName = "replace_memory"
        static let systemMessageBase = """
        You are a helpful assistant. You will get functions to save and access informations you think are worth to keep.
        Informations you saved earlier are saved in the memory, use the function \(Functions.GetMemory.name) to access it.
        Every piece of information you think is worth to keep, save it to the memory with the function \(Functions.SaveMemory.name). This can be for example the preferred language of the user, some characteristics of the user, his favorite artists and so on. Sometimes messages that are not direct answers contain information also. For example the user message "Sometimes I listen to classic music. I like it a lot. Do you have some artist for me?" contains the information "user likes classic music".
        If you accessed a memory and it came out as wrong, you can replace it with \(Functions.ReplaceMemory.name). Always try to replace an information rather than save a new one. But do not come up with informations you do not know.
        
        Some Text examples:
        
        "I am a developer for iOS and I need ideas." contains the information "user is a iOS developer"
        "Yesterday I was at the cinema and watched a great action movie. A genre that I really like." contains the information "user likes action movies"
        "I really need ideas for my job." You will need to access the information "users job is"
        
        Another example: If you know the information "User prefers Pizza" but the user tells you that he does not prefere pizza (either he tells you he likes pasta or you have to ask), replace "User prefers Pizza" with "User prefers Pasta".
        
        Here are some informations about the user that you need to respect and do not need to fetch again:
        {{knowledge}}

        """
        
        static func systemMessage(keyMemories: [Memory]) -> String {
            systemMessageBase.replacingOccurrences(
                of: "{{knowledge}}",
                with: keyMemories.map({ $0.snipped }).joined(separator: "\n")
            )
        }
        
        static let embeddingThreshold = 0.82
    }
}
