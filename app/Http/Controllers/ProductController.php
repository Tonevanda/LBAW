<?php

namespace App\Http\Controllers;

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
}

