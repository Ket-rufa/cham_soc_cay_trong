<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class PlantIdentifyController extends Controller
{
    public function identify(Request $request)
    {
        $request->validate([
            'image' => 'required|image|max:10240',
            'organs' => 'nullable|string',
        ]);

        $apiKey = config('services.plantnet.key', '');
        $apiUrl = config('services.plantnet.url', 'https://my-api.plantnet.org/v2/identify/all');

        if (empty($apiKey)) {
            return response()->json([
                'status' => 503,
                'message' => 'PlantNet API key chưa được cấu hình.',
            ], 503);
        }

        $file = $request->file('image');
        $organ = trim((string) $request->input('organs', 'auto'));
        if ($organ === '') {
            $organ = 'auto';
        }

        try {
            $response = Http::timeout(45)
                ->asMultipart()
                ->attach(
                    'images',
                    file_get_contents($file->getRealPath()),
                    $file->getClientOriginalName()
                )
                ->post($apiUrl, [
                    'api-key' => $apiKey,
                    'include-related-images' => 'false',
                    'no-reject' => 'true',
                    'lang' => 'en',
                    [
                        'name' => 'organs',
                        'contents' => $organ,
                    ],
                ]);

            $body = $response->json();
            if ($body === null) {
                $body = ['raw' => $response->body()];
            }

            if ($response->failed()) {
                return response()->json([
                    'status' => $response->status(),
                    'message' => 'Lỗi từ PlantNet API',
                    'plantnet_response' => $body,
                ], $response->status());
            }

            return response()->json($body, 200);
        } catch (\Throwable $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Lỗi kết nối PlantNet API: ' . $e->getMessage(),
            ], 500);
        }
    }
}