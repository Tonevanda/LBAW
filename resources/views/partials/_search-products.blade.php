@php
    use App\Models\Category;
@endphp

<form class = "products_search" action="" method="GET">
    {{ csrf_field() }}
    <label for="search">Search a product:</label>
    <input type="text" name="search" value = "{{ request('search') }}">
    <label for="category">Select an option:</label>
    <select name="category">
        <option value="" {{ request('category') == '' ? 'selected' : '' }}></option>
        @foreach(Category::all() as $category)
            <option value="{{$category->category_type}}" {{ request('category') == $category->category_type ? 'selected' : '' }}>{{$category->category_type}}</option>
        @endforeach
    </select>
    <label for="price">Select a price:</label>
    <input type="range" name="price" min="0" max="500" step="1" value= "{{ request('price') }}">
    <div>
        {{ request('price') == '' ? '250' : request('price')}}
    </div>
    <button type="submit">Search</button>
</form>