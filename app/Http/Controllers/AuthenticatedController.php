<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Admin;
use App\Models\Product;
use Illuminate\View\View;
use Illuminate\Http\Request;
use App\Models\Authenticated;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Auth\Access\AuthorizationException;

class AuthenticatedController extends Controller
{
    //Show all products in the shopping cart

    public function index(Request $request){
        $users = Authenticated::filter($request->input())->paginate(10);
        try {
            $this->authorize('list', Authenticated::class);
        } catch (AuthorizationException $e) {
            return redirect()->route('all-products');
        }
        return view('user_search', ['users' => $users]);
    }

    public function showShoppingCart($user_id){
        $user = Authenticated::findOrFail($user_id);
        $cart_products = $user->shoppingCart()->get();
        foreach($cart_products as $cart_product){
            try{
                $this->authorize('listCart', [Product::class, $cart_product->pivot->user_id]);
            }
            catch(AuthorizationException $e){
                return redirect()->route('all-products');
            }
        }
        return view('shopping_cart', [
            'products' => $cart_products
        ]);

    }

    public function showPurchases($user_id){
        $user = Authenticated::findOrFail($user_id);
        $purchases = $user->purchases()->get();
        foreach($purchases as $purchase){
            try{
                $this->authorize('list', $purchase);
            }catch (AuthorizationException $e){
                return redirect()->route('all-products');
            }
        }
        return view('purchase_history', [
            'purchases' => $purchases
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
        $user = $auth->user()->first();
        if  (!request()->input('update')){
            $data = [
                'name' => 'deleted user',
                'password' => '',
                'address' => '',
            ];
            $auth->update($data);
            $user->update($data); 
            if (Auth::user()->isAdmin()) {
                return redirect()->route('users')
                ->withSuccess('You have successfully deleted the account!');}
            else{
            Auth::logout();
            session()->invalidate();
            session()->regenerateToken();
            return redirect()->route('login')
                ->withSuccess('You have successfully deleted the account!');}
        }
        else{
            if (Auth::user()->isAdmin()) {
                $data = request()->validate([
                    'name' => 'string|max:250',
                    'email' => ['email', 'max:250', Rule::unique('users')->ignore($user->id)],
                    'password' => ['nullable', 'min:8', 'confirmed'],
                    'address' => 'string|max:250',
                ]);
            }
            else {
                $data = request()->validate([
                    'name' => 'string|max:250',
                    'email' => ['email', 'max:250', Rule::unique('users')->ignore($user->id)],
                    'old_password' => ['required', 'min:8', 'old_password'],
                    'password' => ['nullable', 'min:8', 'confirmed'],
                    'address' => 'string|max:250',
                ]);
            }
            if (!is_null($data['password'])) {
                $data['password'] = Hash::make($data['password']);
            } else {
                unset($data['password']);
            }

            $auth->update($data);
            $user->update($data); 
            Auth::setUser($user->fresh());
            return redirect()->route('profile', $user_id);
        }
    }

    public function updateImage(Request $request, $user_id){
        $auth = Authenticated::findOrFail($user_id);
        $user = $auth->user()->first();
        $data = $request->validate([
            'old_profile_picture' => ['required']
        ]);


        if($data['old_profile_picture'] != "default.png")Storage::disk('public')->delete('images/user_images/' . $data['old_profile_picture']);
        $request->file('profile_picture')->storeAs('images/user_images', $request->file('profile_picture')->getClientOriginalName() ,'public');
        $data['profile_picture'] = $request->file('profile_picture')->getClientOriginalName();

        $user->update($data);
        return response()->json($data['profile_picture'], 200);
    }
    public function showCreateUserForm(): View
    {
        return view('create_user');
    }


    public function showWishlist($user_id){
        $user = Authenticated::findOrFail($user_id);
        $wishlist_products = $user->wishlist()->get();
        foreach($wishlist_products as $wishlist_product){
            try{
                $this->authorize('listWishlist', [Product::class, $wishlist_product->pivot->user_id]);
            }catch(AuthorizationException $e){
                return redirect()->route('all-products');
            }
        }
        return view('wishlist', [
            'products' => $wishlist_products,
            'user' => $user
        ]);
    } 

    
    public function getWishlist($user_id){
        // Get the user's wishlist from the database
        $wishlist = Authenticated::findOrFail($user_id)->wishlist()->get();
        // Return the wishlist as a JSON response
        return response()->json(['wishlist' => $wishlist]);
    }

    public function create(Request $request)
    {

        $request->validate([
            'name' => 'required|string|max:250',
            'email' => 'required|email|max:250|unique:users',
            'password' => 'required|min:8|confirmed',
            'type' => 'required'
        ]);
        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password)
        ]);
        if($request->type == 'Admin'){
            Admin::create([
                'admin_id' => $user->id
            ]);
        }
        else{
            Authenticated::create([
                'user_id' => $user->id,
                'address' => null,
                'isblocked' => false
            ]);
        }

        return redirect()->route('create_user');
    }

    public function store(Request $request, $user_id){
        $user = Authenticated::findOrFail($user_id);
        $data = $request->validate([
            'product_id' => 'required'
        ]);
        $product = Product::findOrFail($data['product_id']);

        try {
            $this->authorize('addToCart', [$product, $user_id]);
        } catch (AuthorizationException $e) {
            return response()->json($e->getMessage(), 301);
        }
        $user->shoppingCart()->attach($data['product_id']);
        return response()->json([], 201);
    }

    public function wishlistStore(Request $request, $user_id){
        $user = Authenticated::findOrFail($user_id);
        $data = $request->validate([
            'product_id' => 'required'
        ]);
        $product = Product::findOrFail($data['product_id']);
        try{
            $this->authorize('addToWishlist', [$product, $user_id]);
        }catch(AuthorizationException $e){
            return response()->json([], 301);
        }
        $user->wishlist()->attach($data['product_id']);
        return response()->json([], 201);
    }

    public function wishlistDestroy(Request $request, $user_id){
        $user = Authenticated::findOrFail($user_id);
        $data = $request->validate([
            'wishlist_id' => 'required'
        ]);
        try {
            $this->authorize('removeFromCart', Product::class);
        } catch (AuthorizationException $e) {
            return response()->json($e->getMessage(), 301);
        }
        $user->wishlist()->wherePivot('id', $data['wishlist_id'])->detach();
        return response()->json($data['wishlist_id'], 200);
    }

    public function destroy(Request $request, $user_id){
        //dd($request);
        $user = Authenticated::findOrFail($user_id);
        $data = $request->validate([
            'cart_id' => 'required'
        ]);


        try {
            $this->authorize('removeFromCart', Product::class);
        } catch (AuthorizationException $e) {
            return response()->json($e->getMessage(), 301);
        }
        $user->shoppingCart()->wherePivot('id', $data['cart_id'])->detach();
        return response()->json($data['cart_id'],200);
    }
}
