<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Producto;

class ProductoController extends Controller
{
    public function create()
    {
        return view('productos.productos_create');
    }

    public function store(Request $request)
    {
        
        $validation = $request->validate([
            'nombre' => 'required|max:255',
            'descripcion' => 'required|max:255',
            'precio' => 'required',
            'cantidad' => 'required',
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
        return view('productos.productos_edit', compact('producto'));
    }

    public function update(Request $request, $id)
    {
        $validation = $request->validate([
            'nombre' => 'required|max:255',
            'descripcion' => 'required|max:255',
            'precio' => 'required',
            'cantidad' => 'required',
        ]);
        $producto = Producto::find($id);
        $producto->update($validation);
        return redirect()->route('productos_index')->with('mensaje', 'Producto actualizado exitosamente!');
    }
}
