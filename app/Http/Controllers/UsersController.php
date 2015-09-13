<?php

namespace App\Http\Controllers;

use App\User;
use File;
use Illuminate\Support\Facades\App;

class UsersController extends Controller
{
    public function getAvatar($id, $type)
    {
        $coverType = Cover::getCoverFromName($type);

        if ($coverType == null) {
            App::abort(404);
        }

        $user = User::find($id);
        if (!$user) {
            App::abort(404);
        }

        return File::inline($user->getAvatarFile($coverType['id']), 'image/png', 'cover.png');
    }
}