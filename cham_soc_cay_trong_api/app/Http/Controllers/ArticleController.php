<?php

namespace App\Http\Controllers;

use App\Models\Article;
use Illuminate\Http\Request;

class ArticleController extends Controller
{
    public function index(Request $request)
    {
        $query = Article::query()
            ->where('is_published', true)
            ->orderBy('sort_order')
            ->orderByDesc('created_at');

        if ($request->filled('category')) {
            $query->where('category', $request->query('category'));
        }

        return response()->json([
            'status' => 200,
            'data' => $query->get(),
        ], 200);
    }

    public function show(int $id)
    {
        $article = Article::where('is_published', true)->find($id);

        if (!$article) {
            return response()->json([
                'status' => 404,
                'message' => 'Article not found.',
            ], 404);
        }

        return response()->json([
            'status' => 200,
            'data' => $article,
        ], 200);
    }
}
