<?php

namespace App\Http\Controllers;

use Illuminate\View\View;
use App\Models\Product;
use Illuminate\Http\Request;
use App\Models\PurchaseProduct;
use Illuminate\Support\Facades\DB;

class ProductController extends Controller
{   
    //Show all products
    public function index(Request $request){
        $products = Product::filter($request->input())->paginate(12);
        return view('products.index', ['products' => $products]);
    }

    //Show a single product
    public function show($product_id)
    {
        $product = Product::findOrFail($product_id);
        $product = Product::with('productStatistic')->findOrFail($product_id);
        $productRevenue = $product->purchaseProducts->sum('price');
        $reviews = $product->reviews()->get();
    
        return view('products.show', [
            'product' => $product,
            'reviews' => $reviews,
            'statistics' => $product->productStatistic,
            'productRevenue' => $productRevenue,
        ]);
    }

    public function showCreateProductForm(): View
    {
        return view('add_product');
    }

    public function createProduct(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:250',
            'synopsis' => 'required|string|max:250',
            'price' => 'required|numeric|min:0',
            'stock' => 'required|numeric|min:0',
            'author' => 'required|string|max:250',
            'editor' => 'required|string|max:250',
            'language' => 'required|string|max:250',
            'image' => 'required|string|min:0',
            #'category' => 'required|string|max:250',
        ]);
        //$imageName = time().'.'.$request->image->extension();  
        //$request->image->move(public_path('images'), $imageName);
        $product = Product::create([
            'name' => $request->name,
            'synopsis' => $request->synopsis,
            'price' => (int)$request->price,
            'stock' => (int)$request->stock,
            'author' => $request->author,
            'editor' => $request->editor,
            'language' => $request->language,
            'image' => $request->image,
            #'category' => $request->category
        ]);
        return redirect()->route('add_products');
    }

}

