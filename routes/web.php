<?php

use Illuminate\Support\Facades\Route;


use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Auth\RegisterController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\AuthenticatedController;
use App\Http\Controllers\PurchaseController;
use App\Http\Controllers\ReviewController;
use App\Http\Controllers\WalletController;
use App\Http\Controllers\PostController;
use Carbon\Carbon;
use App\Models\User;
use GuzzleHttp\Middleware;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/

// Pages
Route::controller(ProductController::class)->group(function () {
    Route::get('/', 'index')->name('all-products');
    Route::get('/products/{product_id}', 'show')->name('single-product');
    Route::get('/product/create', 'showCreateProductForm')->name('add_products');
    Route::post('/product/create', 'createProduct')->name('product.create');
    Route::post('/product/update/{product_id}', 'updateProduct')->name('product.update');
    Route::post('/post/change', 'change')->name('post.change');
});

#->middleware('admin')
#->middleware('guest')
#->middleware('auth')
// API

Route::controller(AuthenticatedController::class)->group(function () {
    Route::post('/api/shopping-cart/{user_id}', 'store')->name('shopping-cart.store');
    Route::delete('/api/shopping-cart/{user_id}', 'destroyCartProduct')->name('shopping-cart.destroy');
    Route::post('/api/wishlist/{user_id}', 'wishlistStore')->name('wishlist.store');
    Route::delete('/api/wishlist/{user_id}', 'wishlistDestroy')->name('wishlist.destroy');
    Route::post('/api/users/{user_id}', 'updateImage')->name('profileImage.update');
});


// Authentication
Route::controller(LoginController::class)->group(function () {
    Route::get('/login', 'showLoginForm')->name('login');
    Route::post('/login', 'authenticate');
    Route::get('/logout', 'logout')->name('logout');
});

Route::controller(RegisterController::class)->group(function () {
    Route::get('/register', 'showRegistrationForm')->name('register')->middleware('guest');
    Route::post('/register', 'register');
});

Route::controller(ReviewController::class)->group(function () {
    Route::post('/review/create/{user_id}', 'store')->name('review.store');
    Route::delete('/review/{review_id}', 'destroy')->name('review.destroy');
    Route::post('/review/{review_id}', 'report')->name('review.report');
    Route::put('/review/{review_id}', 'update')->name('review.update');
});

Route::controller(AuthenticatedController::class)->group(function () {
    Route::get('/shopping-cart/show/{user_id}', 'showShoppingCart')->name('shopping-cart');
    Route::get('/wishlists/{user_id}', 'showWishlist')->name('wishlist');
    Route::get('/users/{user_id}', 'show')->name('profile')->middleware('adminOrAuth');
    Route::get('/user/create', 'showCreateUserForm')->name('create_user');
    Route::post('/user/create', 'create')->name('user.create');
    Route::delete('/users/{user_id}', 'destroy')->name('user.delete');
    Route::get('/users', 'index')->name('users');
    Route::put('/users/{user_id}', 'update')->name('profile.update');
    Route::put('/users/location/{user_id}', 'updateLocation')->name('profile.updateLocation');
    Route::get('/purchase-history/{user_id}', 'showPurchases')->name('purchase_history');
    Route::get('/wishlist/test/{user_id}', 'getWishlist')->name('getWishlist');
    Route::get('/account_details/{user_id}', 'showAccountDetails')->name('account_details');
    Route::get('/notifications/{user_id}', 'showNotifications')->name('notifications');
});

Route::controller(PurchaseController::class)->group(function () {
    Route::post('/checkout/{user_id}', 'store')->name('purchase.store');
});

Route::controller(WalletController::class)->group(function () {
    Route::get('/wallet/{user_id}', 'show')->name('wallet');
    Route::put('/wallet/{user_id}/add', 'update')->name('wallet.update');
});

Route::get('/about_us', function () {
    return view('about_us');
})->name('about_us');

Route::get('/contact_us', function () {
    return view('contact_us');
})->name('contact_us');


