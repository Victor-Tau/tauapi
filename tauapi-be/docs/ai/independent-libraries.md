# RelayKit and TokenKit maintenance

## RelayKit

RelayKit models and converts OpenAI Chat, Responses, Claude Messages and Gemini request,
non-stream response and stream DTOs. Host owns HTTP/SSE I/O, provider selection, authentication,
file loading and billing. Runtime libraries are uuid, lo, gjson and sjson. No host imports.
Chat/Responses conversion quality is good; most other pairs fair; Claude/Gemini discouraged
because requests/responses traverse Chat. Gemini->Responses request/response, Claude->Responses
response and Responses->Gemini response also traverse Chat. Inspect actual Steps/Quality,
not just successful conversion. Streaming state must accumulate conversion diagnostics.
ConvertRequest/ConvertResponse use concrete DTO types; stream creation declares source/target.
Prepare upstream Model before conversion. Parse Claude/Gemini reasoning suffix via reasoning
ParseClaudeModelSuffix/ParseGeminiModelSuffix with ThinkingAdapterEnabled; store StateFromIntent
in Values.ReasoningConversion and use trimmed name. Disabled aliasing preserves model names.
Claude requires max_tokens from source or Claude.DefaultMaxTokens; absent both is error.
Capabilities/options include OpenRouterDialect, WebSearch, PreserveThinkingSuffix/PreserveEffortTail;
consult current types before using a field. Media conversion needs host-registered MediaResolver
GetBase64Data/DecodeBase64FileData; missing resolver is an error, network remains host-owned.
Request/response results retain Value, From/To, Converter, Quality, Steps, Diagnostics;
response adds Usage/Stream. Diagnostics record code, field, message, level and formats.
warning is display loss; error changes content/tool behavior. ToolLossPolicy allow returns all,
safe rejects request errors, strict rejects any request diagnostic with ConversionLossError.
Response/stream conversions complete under every policy; inspect state.Diagnostics even for
chunks emitting no event. Golden matrix tests cover serializations; update snapshots only after
confirming intended behavior. v0.x public API may change in minor versions; verify tools/media/reasoning
and streaming end to end where used. Run GOWORK=off go build ./... and go test ./... in relaykit.

## TokenKit

TokenKit only counts supplied text/images; no host/RelayKit imports, request parsing, downloads or
billing. GPT/o uses tiktoken (GPT4/3.5 cl100k_base; others o200k_base). Claude/Gemini use weighted
estimates. ModelFamily handles case-insensitive vendor/date names; Claude pre4.7 and >=4.7/unknown
version use different weights. Unknown families have uncalibrated estimates. Count selects exact
GPT tokenization; Estimate avoids tokenizer for interrupted streams. Long unbroken segments split
after1024 bytes, creating small differences; whitespace-only indentation may add a token.
Calibration data in the original README is historical measurement, not a guarantee on future models.
Go >=1.26. Public v0.x API/weights/image rules may change in minor releases.

ImageTokens accepts width/height (zero ->1024), detail or Gemini resolution; ImageNeedsSize can
avoid size reads. GPT5.2+/6 uses32px patches and1.2 factor; older GPT/o uses512px tiles+base.
Claude pre4.7 uses ceil(width/28)*ceil(height/28), max edge1568/max1568 patches+4;
newer Claude edge2576/max4784 patches+3. Gemini3 uses resolution280/560/1120/2240 default1120;
Gemini2 <=384 both edges258, else up to12 square tiles*258 plus thumbnail; unknown520.
OpenAI detail low/high/auto/original affects its families; Gemini ignores low and uses its own
MEDIA_RESOLUTION values. GPT5.5+ unspecified detail is original. Measured high-detail rules for
GPT5.5/5.6 resize max2048 then short edge768; GPT6 max2048 then2500 patch budget. Original README
records differences from provider documentation and Gemini measurements; do not present them as
universally exact. Untrusted dimensions >65535 scale down, max30000 patches bounds output.
For image-rule changes, reproduce image-minus-text upstream usage only within separately authorized
provider-test scope. Never send real provider requests merely for a documentation migration.
Run GOWORK=off go build ./... and go test ./... inside tokenkit. Keep each module AGPL attribution
and README original unchanged. Host supplies usage semantics and safety bounds before billing.
