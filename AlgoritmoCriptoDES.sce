//==============================================================================
//= Desarrollo del algoritmo de encriptado DES en Scilab
//= El programa se realiza para el curso de Seguridad en redes Inalambricas
//= de la Escuela de Ingenieria en Telecomunicaciones de la UNSA
//= Creditos:
//=     Editor: Chacon Cadillo Diego Jaffet
//=             chacond233@gmail.com
//=             djchacon@ieee.org
//=
//= "Pero si alguno de vosotros se ve falto de sabiduría, que la pida a Dios,..."
//= Santiago 1:5
//= 
//= Bibliografia:
//= http://www.satorre.eu/descripcion_algoritmo_des.pdf
//= https://www.youtube.com/watch?v=hTLpMm7m5XY
//= 
//= GitHub
//= https://github.com/Diego233/AlgoritmoDES.git
//==============================================================================


//==============================================================================
//=========================    FUNCIONES PRELIMINARES   ========================
//==============================================================================

function ArrayBinario = estirarEnBits(textPlan)
    // Esta funcion crea un array de bits usando el texto plano 
    // El texto plano debe ser de 8 caracteres o menos y mayor que un caracter
    // De ser mayor de ocho caracteres se tomaran los primeros ocho
    if length(textPlan) < 8 then
        while length(textPlan) < 8
            textPlan = textPlan + "0";
        end
    elseif length(textPlan) == 8 then
        textPlan = textPlan;
        
    elseif length(textPlan) > 8 then
        textPlan = part(textPlan,1:8);
    end
    
    ArrayBinario = []
    binarios = dec2bin(ascii(textPlan),8)
    for i=1:8
        for j=1:8
            ArrayBinario = [ArrayBinario, part(binarios(i),j)];
        end
    end
    ArrayBinario = strtod(ArrayBinario)
endfunction

function out = permutador(ArrayBinario, MatrizPermutadora)
    //Esta funcion permuta los valores de Array de bits en funcion de la MAtriz 
    //Permutadora la salida sera una matriz de datos binarios con la forma
    //de La MAtriz Permutadora
    [f, c] = size(MatrizPermutadora);
    out = ones(f, c);
    
    for i = 1:f
        for j = 1:c
            out(i,j) = ArrayBinario(MatrizPermutadora(i,j));
        end
    end
endfunction

function out = RotarMatriz(M, columnas)
    //Esta funcion rota las columnas de una matriz hacia la izquierda
    [f,c] = size(M);
    out = [ out(:,columnas+1:c), out(:,1:columnas)]
endfunction

//==============================================================================
//============================    ALGORITMO DES     ============================
//==============================================================================

//iNFORMACION DE INICIO

clave = "ochobits"
textoPlano = "Este es un texto de pruba para el algoritmo DES"

//1.PROCESAR LA CLAVE

//1.1 Solicitar clave y convertirla en binarios

A = estirarEnBits(clave)
//1.2 Calcular las subclaves

PC1 =  [57,49,41,33,25,17,9;
        1,58,50,42,34,26,18;
        10,2,59,51,43,35,27;
        19,11,3,60,52,44,36;
        63,55,47,39,31,23,15;
        7,62,54,46,38,30,22;
        14,6,61,53,45,37,29;
        21,13,5,28,20,12,4];

//Calculo de clave Permutada
clavePermu = permutador(A, PC1)

//Generar llaves
PC2 =  [14,17,11,24,1,5;
        3,28,15,6,21,10;
        23,19,12,4,26,8;
        16,7,27,20,16,2;
        41,52,31,37,47,55;
        30,40,51,45,33,48;
        44,49,39,56,34,53;
        46,42,50,36,29,32];
        
Ks = []

a = [1 1 2 2 2 2 2 2 1 2 2 2 2 2 2 1]

for i = 1:16
    clavePermu = RotarMatriz(clavePermu, a(i));
    Ks = [Ks; permutador(clavePermu, PC2)];
end

Ks = matrix(Ks, 8, 6, 16);

//2. PROCESAR EL TEXTO PLANO

IP =  [58,50,42,34,26,18,10,2;
       60,52,44,36,28,20,12,4;
       62,54,46,38,30,22,14,6;
       64,56,48,40,32,24,16,8;
       57,49,41,33,25,17,9,1;
       59,51,43,35,27,19,11,3;
       61,53,45,37,29,21,13,5;
       63,55,47,39,31,23,15,7];

//Separamos en bloques de ocho caractere, si faltan no hay problema
T = []
while length(textoPlano) > 8
    T = [T, part(textoPlano,1:8)]
    textoPlano = part(textoPlano,9:length(textoPlano))
end
T = [T, textoPlano]

//Converimos cada caracter en binario cada grupo de ocho caracteres en una bloque y 
//juntamos los bloques en una matriz de 3 dimenciones
TBinarios = []
for i=1:length(length(T))
    TBinarios = [TBinarios, estirarEnBits(T(i))]
end
TBinarios = matrix(TBinarios,8,8, length(length(T)))

//Realizamos la permutacion con IP (Permutacion Inicial) a cada bloque y creamos
//una nueva matriz de 3 dimenciones
TextoPermut = []
for i=1:length(length(T))
    TextoPermut = [TextoPermut; permutador(TBinarios(:,:,i),IP)]
end
TextoPermut = matrix(TextoPermut,8,8, length(length(T)))

//Ya todo esta listo para continuar con la segunda parte del algoritmo

//3. Dividimos cada bloque de 64en dos grupos de 32 bits y lo expandimos a 48 bits

E = [32,1,2,3,4,5,4,5;
     6,7,8,9,8,9,10,11;
     12,13,12,13,14,15,16,17;
     16,17,18,19,20,21,20,21;
     22,23,24,25,24,25,26,27;
     28,29,28,29,30,31,32,1]

TExpandido = []
for i=1:length(length(T))
    TExpandido = [TExpandido; 
                  permutador(TextoPermut(1:4,:,i),E); 
                  permutador(TextoPermut(5:8,:,i),E)]
end
TExpandido = matrix(TExpandido, 12,8,length(length(T)))
