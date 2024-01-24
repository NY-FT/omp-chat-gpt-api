/**
 * Pode ser feito com HTTP ou samp-node para fazer a conexão com a API.
 * Optei pelo `pawn-requests` com uma include extra do pacote YSI "y_inline_requests".
 *
 * Credits:
 *    - Southclaws (https://github.com/Southclaws/pawn-requests).
 *    - Y-Less & Equip (https://github.com/pawn-lang/YSI-Includes).
 */

#define MAX_PLAYERS (2)

#include <open.mp>
#include <requests>

#define YSI_NO_HEAP_MALLOC

#include <YSI_Extra\y_inline_requests>

/**
 * # Header
 */

#define API_OPEN_AI_MOD             "gpt-3.5-turbo-1106" // https://platform.openai.com/docs/models
#define API_OPEN_AI_END             "https://api.openai.com/v1/chat/completions"
#define API_OPEN_AI_KEY             "CHAVE_DA_API_AQUI" // https://platform.openai.com/api-keys

#define API_OPEN_AI_MAX_TOKENS      (128)
#define API_OPEN_AI_TEMPERATURE     (0.8)

new
    RequestsClient:gClient[MAX_PLAYERS]
;

main() {}

/**
 * # Functions
 */

AskChatGPT(playerid, const text[]) {
    if (!IsValidRequestsClient(gClient[playerid])) {
        return 0;
    }

    inline const APIResponse(Request:id, E_HTTP_STATUS:status, Node:node) {
        #pragma unused id

        if (status == HTTP_STATUS_OK) {
            new
                Node:choice
            ;

            JsonGetArray(node, "choices", choice);

            if (JsonNodeType(choice) == JSON_NODE_ARRAY) {
                new
                    Node:first,
                    Node:message
                ;

                JsonArrayObject(choice, 0, first);
                JsonGetObject(first, "message", message);

                if (JsonNodeType(message) == JSON_NODE_OBJECT) {
                    new
                        content[API_OPEN_AI_MAX_TOKENS + 1]
                    ;

                    JsonGetString(message, "content", content);

                    /**
                     * Isso leva um tempo para ser respondido, usar tarefas do PawnPlus pode resolver esse problema para exibir a mensagem toda vez.
                     */

                    SendClientMessage(playerid, -1, "ChatGPT: %s", content);
                }
            }
        }
    }

    RequestJSONCallback(gClient[playerid], "", HTTP_METHOD_POST, using inline APIResponse,
        JsonObject(
            "model", JsonString(""#API_OPEN_AI_MOD""),
            "messages", JsonArray(
                JsonObject(
                    "role", JsonString("user"),
                    "content", JsonString(text)
                )
            ),
            "max_tokens", JsonInt(API_OPEN_AI_MAX_TOKENS),
            "temperature", JsonFloat(API_OPEN_AI_TEMPERATURE)
        ),
        RequestHeaders()
    );

    return 1;
}

/**
 * # Callbacks
 */

public OnPlayerSpawn(playerid) {
    gClient[playerid] = RequestsClient(API_OPEN_AI_END,
        RequestHeaders(
            "Content-Type", "application/json",
            "Authorization", "Bearer "#API_OPEN_AI_KEY""
        )
    );
    
    return 1;
}

public OnPlayerText(playerid, text[]) {
    /**
     * Usar acentuação nas palavras em `text` irá crashar o servidor.
     */

    AskChatGPT(playerid, text);
    
    return 1;
}
