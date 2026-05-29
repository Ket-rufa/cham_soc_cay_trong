<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 400,
                'errors' => $validator->errors(),
            ], 400);
        }

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
        ]);

        return response()->json([
            'status' => 200,
            'message' => 'Đăng ký thành công',
            'data' => $this->formatUserData($user, $request),
        ]);
    }

    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 400,
                'errors' => $validator->errors(),
            ], 400);
        }

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'status' => 401,
                'message' => 'Sai email hoặc mật khẩu',
            ], 401);
        }

        return response()->json([
            'status' => 200,
            'message' => 'Đăng nhập thành công',
            'data' => $this->formatUserData($user, $request),
        ]);
    }

    public function updateProfile(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|integer|exists:users,id',
            'name' => 'required|string|min:2|max:255',
            'avatar' => 'nullable|image|max:4096',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 400,
                'errors' => $validator->errors(),
            ], 400);
        }

        $user = User::findOrFail($request->user_id);
        $user->name = $request->name;
        $user->save();

        if ($request->hasFile('avatar')) {
            $avatarDirectory = public_path('uploads/avatars');

            if (!File::exists($avatarDirectory)) {
                File::makeDirectory($avatarDirectory, 0755, true);
            }

            foreach (glob($avatarDirectory . DIRECTORY_SEPARATOR . 'user_' . $user->id . '.*') ?: [] as $oldFile) {
                @unlink($oldFile);
            }

            $extension = $request->file('avatar')->getClientOriginalExtension() ?: 'jpg';
            $fileName = 'user_' . $user->id . '.' . strtolower($extension);
            $request->file('avatar')->move($avatarDirectory, $fileName);
        }

        $user->refresh();

        return response()->json([
            'status' => 200,
            'message' => 'Cập nhật thông tin cá nhân thành công',
            'data' => $this->formatUserData($user, $request),
        ]);
    }

    public function changePassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|integer|exists:users,id',
            'current_password' => 'required|string',
            'password' => 'required|string|min:6|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 400,
                'errors' => $validator->errors(),
            ], 400);
        }

        $user = User::findOrFail($request->user_id);

        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'status' => 422,
                'message' => 'Mật khẩu hiện tại không đúng',
            ], 422);
        }

        $user->password = Hash::make($request->password);
        $user->save();

        return response()->json([
            'status' => 200,
            'message' => 'Đổi mật khẩu thành công',
        ]);
    }

    public function showAvatar(Request $request, int $userId)
    {
        $user = User::findOrFail($userId);
        $avatarFile = $this->findAvatarFile($user);

        if ($avatarFile === null) {
            abort(404);
        }

        return response()->file($avatarFile, [
            'Cache-Control' => 'public, max-age=86400',
        ]);
    }

    private function formatUserData(User $user, Request $request): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'avatar_url' => $this->avatarUrl($user, $request),
            'created_at' => $user->created_at,
            'updated_at' => $user->updated_at,
        ];
    }

    private function avatarUrl(User $user, Request $request): ?string
    {
        $avatarFile = $this->findAvatarFile($user);
        if ($avatarFile === null) {
            return null;
        }

        $baseUrl = rtrim((string) config('app.url'), '/');
        if ($baseUrl === '') {
            $baseUrl = rtrim($request->getSchemeAndHttpHost(), '/');
        }
        $version = @filemtime($avatarFile) ?: time();

        return $baseUrl . '/api/profile/avatar/' . $user->id . '?v=' . $version;
    }

    private function findAvatarFile(User $user): ?string
    {
        $avatarFiles = glob(
            public_path('uploads/avatars/user_' . $user->id . '.*')
        ) ?: [];

        if (empty($avatarFiles)) {
            return null;
        }

        return $avatarFiles[0];
    }
}
