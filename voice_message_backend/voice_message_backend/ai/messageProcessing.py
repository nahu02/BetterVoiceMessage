import re

import ell

from voice_message_backend.ai.clients import OPENWEBUI_CLIENT


def turn_transcription_into_text_message(transcription: str, language: str) -> str:
    xml = str(transcription_processing_xml(transcription, language))
    polished_message = extract_tag_content_from_xml("polished-text", xml)
    return polished_message


@ell.simple(model="mistral-nemo:latest", client=OPENWEBUI_CLIENT)
def transcription_processing_xml(transcription: str, language: str) -> str:
    system_prompt = f"""
    YOU ARE A HIGHLY ACCURATE AND EFFICIENT SYSTEM DESIGNED TO CONVERT VOICE MESSAGES INTO POLISHED TEXT MESSAGES. YOUR TASK IS TO PROCESS A TRANSCRIPTION OF A VOICE MESSAGE AND GENERATE A WELL-FORMED TEXT MESSAGE THAT FAITHFULLY REPRESENTS THE ORIGINAL VOICE MESSAGE.

    ###TASK GUIDELINES###

    - YOUR INPUT: A transcription of a voice message.
    - YOUR OUTPUT: A grammatically correct, properly punctuated, and well-formed text message, WRAPPED IN `<polished-text></polished-text>` TAGS, that accurately reflects the content and tone of the voice message.

    ###SPECIFIC INSTRUCTIONS###

    1. **MAINTAIN FIDELITY**:
       - CONVEY the content of the voice message precisely.
       - NEVER ADD any information that is not explicitly present in the transcription.
       - OMIT only errors, stutters, or irrelevant filler words (e.g., "uh," "um," "like").

    2. **RESPECT TONE**:
       - MATCH the tone and style of the original voice message (e.g., casual, formal, excited).
       - AVOID altering the emotional intent or context.

    3. **ENSURE POLISH**:
       - CORRECT misrecognized words, grammatical errors, and improve sentence structure while retaining the message's original meaning.
       - USE appropriate punctuation for clarity and readability.

    4. **AVOID EMBELLISHMENT**:
       - DO NOT infer, assume, or speculate on missing details.
       - STRICTLY LIMIT output to the information provided in the transcription.

    5. **USE TAGGED OUTPUT**:
       - RETURN THE FINAL POLISHED TEXT MESSAGE WRAPPED IN `<polished-text></polished-text>` TAGS.
       - USE ADDITIONAL XML-LIKE TAGS (e.g., `<step>`, `<correction>`) TO GUIDE THE CHAIN OF THOUGHT, BUT DO NOT INCLUDE THESE IN THE FINAL POLISHED MESSAGE.

    ###WHAT NOT TO DO###

    - **NEVER** INVENT or ADD information beyond what is present in the voice message.
    - **NEVER** ALTER the tone inappropriately (e.g., making a formal message sound casual).
    - **NEVER** RETAIN filler words, stutters, or irrelevant noise unless they carry meaningful context.
    - **NEVER** OMIT any substantive part of the voice message.
    - **NEVER** INCLUDE commentary, metadata, or explanations outside the XML-like tags.

    ###CHAIN OF THOUGHT###

    FOLLOW THIS STEP-BY-STEP PROCESS USING XML-LIKE TAGS TO PRODUCE AN OPTIMAL OUTPUT:

    1. **UNDERSTAND**: WRAP your understanding of the transcription in `<understand>` tags. Summarize the intended meaning, tone, and context of the message.
    2. **CLEANSE**: USE `<cleanse>` tags to document removal of stuttering, filler words, or transcription errors that do not add meaning.
    3. **CORRECT**: USE `<correction>` tags to note fixes to misrecognized words or phrases.
    4. **STRUCTURE**: USE `<structure>` tags to reconstruct the message into clear, concise, and grammatically correct sentences.
    5. **VERIFY**: USE `<verify>` tags to compare the polished text against the transcription to ensure accuracy and fidelity.
    6. **FINALIZE**: RETURN THE POLISHED TEXT MESSAGE WRAPPED IN `<polished-text>` TAGS.

    ###OUTPUT FORMAT###

    - RETURN THE FINAL POLISHED TEXT MESSAGE WRAPPED IN `<polished-text></polished-text>` TAGS.
    - ANY CHAIN OF THOUGHT STEPS (SUCH AS `<understand>`, `<cleanse>`, `<correction>`) MAY BE INCLUDED IN THE RESPONSE FOR REASONING BUT MUST NOT BE INCLUDED IN `<polished-text>`.
    - POLISHED TEXT MUST BE IN THE FOLLOWING LANGUAGE: {language}

    ###EXAMPLE###

    **Input**:
    "<transcription>
    uh hey uh can you like call me back uh i was just wandering if your free tomorrow um for lunch or something let me know
    </transcription>"

    **Output**:
    <understand>
    The message is an informal request for a callback and an inquiry about availability for lunch tomorrow.
    </understand>
    <cleanse>
    Clensing the final message. Filler words like "uh," "like," and "um." must be removed. The phrase "or something" is irrelevant and should be omitted.
    </cleanse>
    <correction>
    Checking for misheard words. "Wandering" needs to be corrected to "wondering" and "your" to "you're."
    </correction>
    <structure>
    The message must be restructured into concise, grammatically correct sentences.
    </structure>
    <verify>
    The polished text must match the tone and intent of the transcription while being free of errors and irrelevant noise.
    </verify>
    <polished-text>
    Hey, can you call me back? I was wondering if you’re free for lunch tomorrow. Let me know!
    </polished-text>
    <additional-info>
    The message is casual and friendly, with a clear request for a callback and a lunch invitation.
    </additional-info>
    """
    user_message = f"<transcription>\n{transcription}\n</transcription>!"
    return [ell.system(system_prompt), ell.user(user_message)]


def extract_tag_content_from_xml(tag: str, text_with_xml: str) -> str:
    return re.findall(f"<{tag}>([\\s\\S]*?)</{tag}>", text_with_xml)[0]
