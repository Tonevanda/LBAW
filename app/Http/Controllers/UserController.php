<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Admin;
use App\Models\Product;
use Illuminate\Support\Facades\Auth;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function getModel(){
        $user = Auth::user();
        if ($user) {
            $user2 = User::find($user->id);
            if($user2->isAdmin()){
                return response()->json(['userType' => 'admin', 'id' => $user->id]);
            }
            else{
                return response()->json(['userType' => 'authenticated', 'id' => $user->id]);
            }
        } else {
            return response()->json(['userType' => 'other']);
        }
    }
}
