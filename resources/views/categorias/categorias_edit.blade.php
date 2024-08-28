<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet"
        integrity="sha384-EVSTQN3/azprG1Anm3QDgpJLIm9Nao0Yz1ztcQTwFspd3yD65VohhpuuCOmLASjC" crossorigin="anonymous">
    <title>Editar categoría</title>
</head>

<body>

    @extends('layouts_productos.app')

    @section('content')
        <form class="row g-3 needs-validation" novalidate action="{{ route('categorias_update', $categoria) }}" method="POST">
            @csrf
            @method('PUT')
            <div class="col-md-6">
                <label for="nombre" class="form-label">Nombre de la categoría</label>
                <input type="text" class="form-control" id="nombre" placeholder="Nombre" name="nombre" value="{{ $categoria->nombre }}" required>
                <div class="invalid-feedback">
                    Introduzca un nombre por favor!
                </div>
                <div class="valid-feedback">
                    Campo válido
                </div>
            </div>
            <div class="col-md-6">
                <label for="descripcion" class="form-label">Descripción</label>
                <input type="text" class="form-control" id="descripcion" placeholder="Descripción" name="descripcion" value="{{ $categoria->descripcion }}" required>
                <div class="invalid-feedback">
                    Introduzca una descripción por favor!
                </div>
                <div class="valid-feedback">
                    Campo válido
                </div>
            </div>

            <div class="col-12">
                <button class="btn btn-primary" type="submit">Editar categoría</button>
            </div>
        </form>
        <script>
            (function() {
                'use strict'

                var forms = document.querySelectorAll('.needs-validation')

                Array.prototype.slice.call(forms)
                    .forEach(function(form) {
                        form.addEventListener('submit', function(event) {
                            if (!form.checkValidity()) {
                                event.preventDefault()
                                event.stopPropagation()
                            }

                            form.classList.add('was-validated')
                        }, false)
                    })
            })()
        </script>
    @endsection
</body>

</html>

