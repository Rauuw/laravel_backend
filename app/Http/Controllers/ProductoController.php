<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Producto;
use App\Models\Categoria;

class ProductoController extends Controller
{
    public function create()
    {
        $categorias = Categoria::all();
        return view('productos.productos_create', compact('categorias'));
    }

    public function store(Request $request)
    {
        
        $validation = $request->validate([
            'nombre' => 'required|max:255',
            'descripcion' => 'required|max:255',
            'precio' => 'required',
            'cantidad' => 'required',
            'categoria_id' => 'required',
        ]);

        Producto::create($validation);

        return redirect()->route('productos_index')->with('mensaje', 'Producto creado exitosamente!');
    }

    public function index()
    {
        $productos = Producto::all();
        return view('productos.productos_index', compact('productos'));
    }

    public function destroy($id)
    {
        $producto = Producto::find($id);
        $producto->delete();
        return redirect()->route('productos_index')->with('mensaje', 'Producto eliminado exitosamente!');
    }

    public function edit($id)
    {
        $producto = Producto::find($id);
        $categorias = Categoria::all();
        return view('productos.productos_edit', compact('producto', 'categorias'));
    }

    public function update(Request $request, $id)
    {
        $validation = $request->validate([
            'nombre' => 'required|max:255',
            'descripcion' => 'required|max:255',
            'precio' => 'required',
            'cantidad' => 'required',
            'categoria_id' => 'required',
        ]);
        $producto = Producto::find($id);
        $producto->update($validation);
        return redirect()->route('productos_index')->with('mensaje', 'Producto actualizado exitosamente!');
    }
}
