import Debug "mo:base/Debug";
import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Error "mo:base/Error";
import Array "mo:base/Array";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Text "mo:base/Text";
import Types "Types";
import JSON "mo:json";

actor {
    // Create a function that transform's the raw content into an HTTP payload.
    public query func transform(raw : Types.TransformArgs) : async Types.CanisterHttpResponsePayload {
        let transformed : Types.CanisterHttpResponsePayload = {
            status = raw.response.status;
            body = raw.response.body;
            headers = [
                {
                    name = "Content-Security-Policy";
                    value = "default-src 'self'"
                },
                { name = "Referrer-Policy"; value = "strict-origin" },
                { name = "Permissions-Policy"; value = "geolocation=(self)" },
                {
                    name = "Strict-Transport-Security";
                    value = "max-age=63072000"
                },
                { name = "X-Frame-Options"; value = "DENY" },
                { name = "X-Content-Type-Options"; value = "nosniff" }
            ]
        };
        transformed
    };

    // This function sends our GET request
	public func get_icp_usd_exchange() : async Text {
        //First, declare the management canister
        let ic : Types.IC = actor ("aaaaa-aa");

        //Next, you need to set the arguments for our GET request
        // Start with the URL and its query parameters
        let ONE_MINUTE : Nat64 = 60;
        let start_timestamp : Types.Timestamp = 1682978460; //May 1, 2023 22:01:00 GMT
        let end_timestamp : Types.Timestamp = 1682978520;//May 1, 2023 22:02:00 GMT
        // let host : Text = "api.coinbase.com";
		let host : Text = "api.kraken.com";

        // let url = "https://" # host # "/products/ICP-USD/candles?start=" # Nat64.toText(start_timestamp) # "&end=" # Nat64.toText(end_timestamp) # "&granularity=" # Nat64.toText(ONE_MINUTE);
		// let url = "https://" # host # "/0/public/OHLC?pair=ICPUSD&interval=1&since=" # Nat64.toText(start_timestamp);
		let url = "https://" # host # "/0/public/OHLC?pair=ICPUSD&interval=" # Nat64.toText(ONE_MINUTE) # "&since=" # Nat64.toText(start_timestamp);

        // Prepare headers for the system http_request call.
        let request_headers = [
            { name = "Host"; value = host # ":443" },
            { name = "User-Agent"; value = "exchange_rate_canister" },
        ];

        // Next, you define a function to transform the request's context from a blob datatype to an array.
        let transform_context : Types.TransformContext = {
            function = transform;
            context = Blob.fromArray([]);
        };

        // Finally, define the HTTP request.
        let http_request : Types.HttpRequestArgs = {
            url = url;
            max_response_bytes = null; //optional for request
            headers = request_headers;
            body = null; //optional for request
            method = #get;
            transform = ?transform_context;
        };

        // Now, you need to add some cycles to your call, since cycles to pay for the call must be transferred with the call.
        // The way Cycles.add() works is that it adds those cycles to the next asynchronous call.
        // "Function add(amount) indicates the additional amount of cycles to be transferred in the next remote call".
        // See: https://internetcomputer.org/docs/current/references/ic-interface-spec#ic-http_request
        Cycles.add(20_949_972_000);

        // Now that you have the HTTP request and cycles to send with the call, you can make the HTTP request and await the response.
        let http_response : Types.HttpResponsePayload = await ic.http_request(http_request);

        // Once you have the response, you need to decode it. The body of the HTTP response should come back as [Nat8], which needs to be decoded into readable text.
        // To do this, you:
        //  1. Convert the [Nat8] into a Blob
        //  2. Use Blob.decodeUtf8() method to convert the Blob to a ?Text optional
        //  3. Use a switch to explicitly call out both cases of decoding the Blob into ?Text
        let response_body: Blob = Blob.fromArray(http_response.body);
        // Let's see what we have:
        Debug.print("Raw response body as Blob: " # debug_show(response_body));

        let decoded_text: Text = switch (Text.decodeUtf8(response_body)) {
            case (null) { "No value returned" };
            case (?y) { y };
        };
        // Debug.print("Decoded text: " # decoded_text);

        // Parse the JSON response
        let parsed_result = switch (JSON.parse(decoded_text)) {
            case (#err(err)) { "Failed to parse JSON: " # debug_show(err) };
            case (#ok(#object_(fields))) {
                let result_tuple = fields[1];  // Get the second tuple (index 1) which is ("result", ...)
                switch (result_tuple.1) {
                    case (#object_(result_fields)) {
                        let icpusd_tuple = result_fields[0];  // Get ICPUSD array
                        switch (icpusd_tuple.1) {
                            case (#array(entries)) {
                                if (entries.size() > 0) {
                                    "First entry: " # debug_show(entries[0])
                                } else {
                                    "No entries found"
                                };
                            };
                            case (_) { "Not an array" };
                        };
                    };
                    case (_) { "Not an object" };
                };
            };
            case (#ok(_)) { "Not an object" };
        };

        // Print the complete decoded response for inspection
        // debug_show(decoded_text) # "\n\nParsed result: " # parsed_result
		// Print the decoded text
		// decoded_text
    };
}