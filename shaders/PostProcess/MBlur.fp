
void main()
{
	vec3 C = vec3( 0. );
	
	switch( blendmode )
	{
	//Normal
	case 0:
		for( int i = 0; i < samples; i++ )
		{
			C += texture( InputTexture, TexCoord + steps * i ).rgb * increment ;
		}
		break ;
		
	//Lighten
	case 1:
		for( int i = 0; i < samples; i++ )
		{
			C += max( C, texture( InputTexture, TexCoord + steps * i ).rgb ) * increment ;
		}
		break ;
	}
	
	FragColor = vec4( C, 1. );
}
