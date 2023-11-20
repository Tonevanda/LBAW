<?php

namespace App\Http\Controllers;

use Illuminate\View\View;
use Illuminate\Http\Request;
use App\Models\Authenticated;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;

class AuthenticatedController extends Controller
{
    //Show all products in the shopping cart
    
    public function index(Request $request){
        $users = Authenticated::filter($request->input())->paginate(10);
        return view('user_search', ['users' => $users]);
    }

    public function showShoppingCart($user_id){
        $user = Authenticated::findOrFail($user_id);
        return view('shopping_cart', [
            'products' => $user->shoppingCart()->get()
        ]);
    }
    
    public function showPurchases($user_id){
        $user = Authenticated::findOrFail($user_id);
        return view('purchase_history', [
            'purchases' => $user->purchases()->get()
        ]);
    }
    
    //Show Profile
    public function show($user_id){
        $user = Authenticated::findOrFail($user_id);
        return view('profile', [
            'user' => $user
        ]);
    }
    //Update Profile
    public function update($user_id){
        $auth = Authenticated::findOrFail($user_id);
        $user = $auth->user()->get()[0];
<<<<<<< HEAD
=======
        #dd('ok');
>>>>>>> 594188e63cf8fa9db91778ee538cb3522b5adf74
        $data = request()->validate([
            'profile_picture' => ['required'],
            'name' => 'string|max:250',
            'email' => ['email', 'max:250', Rule::unique('users')->ignore($user->id)],
            'old_password' => ['required', 'min:8', 'old_password'],
            'password' => ['nullable', 'min:8', 'confirmed'],
            'address' => 'string|max:250',
        ]);
<<<<<<< HEAD
        $credentials = [
            'email' => $user->email,
            'password' => $data['old_password']
        ];
        if (Auth::attempt($credentials)) {
            dd('ok');
        }
        $auth->update($data);
        $user->update($data);
=======
        if (!is_null($data['password'])) {
            $data['password'] = Hash::make($data['password']);
        } else {
            unset($data['password']);
        }
        $auth->update($data);
        $user->update($data);
        Auth::setUser($user->fresh());
>>>>>>> 594188e63cf8fa9db91778ee538cb3522b5adf74
        return view('profile');
    }
    public function store(Request $request, $user_id){
        $user = Authenticated::findOrFail($user_id);
        $data = $request->validate([
            'product_id' => 'required'
        ]);
        $user->shoppingCart()->attach($data['product_id']);
    }

    public function destroy(Request $request, $user_id){
        $user = Authenticated::findOrFail($user_id);
        $data = $request->validate([
            'cart_id' => 'required'
        ]);
        $user->shoppingCart()->wherePivot('id', $data['cart_id'])->detach();
        return response()->json($data['cart_id']);
    }
}
