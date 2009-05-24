/*
 * Copyright (c) 2006, Lee McColl Sylvester - www.designrealm.co.uk
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
 
#include "nsdl.h"
#include "nme.h"

/*
	SDL surface test if offset (u,v) is a transparent pixel
*/

bool nme_collision_transparentpixel(SDL_Surface *surface , int u , int v)
{
	/*assert that (u,v) offsets lie within surface*/
	if( !((u < surface->w) || (v < surface->h)) )
		return false;

	int bpp = surface->format->BytesPerPixel;
	/*here p is the address to the pixel we want to retrieve*/
	Uint8 *p = (Uint8 *)surface->pixels + v * surface->pitch + u * bpp;

	Uint32 pixelcolor;

	switch(bpp)
	{
		case(1):
			pixelcolor = *p;
		break;

		case(2):
			pixelcolor = *(Uint16 *)p;
		break;

		case(3):
			if(SDL_BYTEORDER == SDL_BIG_ENDIAN)
				pixelcolor = p[0] << 16 | p[1] << 8 | p[2];
			else
				pixelcolor = p[0] | p[1] << 8 | p[2] << 16;
		break;

		case(4):
			pixelcolor = *(Uint32 *)p;
		break;
	}

	/*test whether pixels color == color of transparent pixels for that surface*/
	return (pixelcolor == surface->format->colorkey);
}

value nme_collision_pixel( value asurf, value arect,
						  value bsurf, value brect, value point )
{
	/*Box A;
	Box B;*/
	val_check_kind( asurf, k_surf );
	val_check_kind( bsurf, k_surf );

	val_check( arect, object );
	val_check( brect, object );
	val_check( point, object );

	int x = 0;
	int y = 0;
	int w = INT_FIELD( point, "x" );
	int h = INT_FIELD( point, "y" );
	int ax = INT_FIELD( arect, "x" );
	int ay = INT_FIELD( arect, "y" );
	int aw = INT_FIELD( arect, "w" );
	int ah = INT_FIELD( arect, "h" );
	int bx = INT_FIELD( brect, "x" );
	int by = INT_FIELD( brect, "y" );
	int bw = INT_FIELD( brect, "w" );
	int bh = INT_FIELD( brect, "h" );

	/*a - bottom right co-ordinates*/
	int ax1 = x + aw - 1;
	int ay1 = y + ah - 1;
	
	/*b - bottom right co-ordinates*/
	int bx1 = w + bw - 1;
	int by1 = h + bh - 1;

	/*check if bounding boxes intersect*/
	if ( ( bx1 < x ) || ( ax1 < w ) || ( by1 < y ) || ( ay1 < h ) )
		return alloc_bool( false );


/*Now lets make the bounding box for which we check for a pixel collision*/

	/*To get the bounding box we do
	    Ax1,Ay1_____________
		|					|
		|					|
		|					|
		|		Bx1,By1_________________
		|			|		|			|
		|			|		|			|
		|___________|_______|			|
					|    Ax2,Ay2		|
					|					|
					|					|
					|________________Bx2,By2

	To find that overlap we find the biggest left hand cordinate
	AND the smallest right hand co-ordinate

	To find it for y we do the biggest top y value
	AND the smallest bottom y value

	Therefore the overlap here is Bx1,By1 --> Ax2,Ay2

	Remember	Ax2 = Ax1 + SA->w
			Bx2 = Bx1 + SB->w

			Ay2 = Ay1 + SA->h
			By2 = By1 + SB->h
	*/

	/*now we loop round every pixel in area of
	intersection
		if 2 pixels alpha values on 2 surfaces at the
		same place != 0 then we have a collision*/
	int inter_x0 = MAX(x,w);
	int inter_x1 = MIN(ax1,bx1);

	int inter_y0 = MAX(y,h);
	int inter_y1 = MIN(ay1,by1);

	bool check = false;

	for(int ly = inter_y0 ; ly <= inter_y1 ; ly++)
	{
		for(int lx = inter_x0 ; lx <= inter_x1 ; lx++)
		{
			/*compute offsets for surface
			before pass to TransparentPixel test*/
			SDL_Surface* as = SURFACE( asurf );
			SDL_Surface* bs = SURFACE( bsurf );
			int atest = nme_collision_transparentpixel( as, lx + ax, ly + ay );
			int btest = nme_collision_transparentpixel( bs, (lx + bx) - w, (ly + by) - h );
			if( !atest && !btest )
				check = true;
		}
	}
	return alloc_bool( check );
}

/*
	SDL bounding box collision test
*/
value nme_collision_boundingbox( value arect, value brect, value point )
{
	val_check( arect, object );
	val_check( brect, object );
	val_check( point, object );

	int x = 0;
	int y = 0;
	int w = INT_FIELD( point, "x" );
	int h = INT_FIELD( point, "y" );
	int ax = INT_FIELD( arect, "x" );
	int ay = INT_FIELD( arect, "y" );
	int aw = INT_FIELD( arect, "w" );
	int ah = INT_FIELD( arect, "h" );
	int bx = INT_FIELD( brect, "x" );
	int by = INT_FIELD( brect, "y" );
	int bw = INT_FIELD( brect, "w" );
	int bh = INT_FIELD( brect, "h" );

	/*a - bottom right co-ordinates*/
	int ax1 = x + aw - 1;
	int ay1 = y + ah - 1;
	
	/*b - bottom right co-ordinates*/
	int bx1 = w + bw - 1;
	int by1 = h + bh - 1;

	/*check if bounding boxes intersect*/
	if ( ( bx1 < x ) || ( ax1 < w ) || ( by1 < y ) || ( ay1 < h ) )
		return alloc_bool( false );

	return alloc_bool( true );				//bounding boxes intersect
}

/*
	tests whether 2 circles intersect

	circle1 : centre (x1,y1) with radius r1
	circle2 : centre (x2,y2) with radius r2
	
	(allow distance between circles of offset)
*/
value nme_collision_boundingcircle( value rp1, value rp2, value poffset )
{
	val_check( rp1, int );
	val_check( rp2, int );
	val_check( poffset, object );

	int r1 = val_int( rp1 );
	int r2 = val_int( rp2 );
	int xdiff = INT_FIELD( poffset, "x" );
	int ydiff = INT_FIELD( poffset, "y" );

	/* distance between the circles centres squared */
	int dcentre_sq = (ydiff*ydiff) + (xdiff*xdiff);
	
	/* calculate sum of radiuses squared */
	int r_sum_sq = r1 + r2;	// square on seperate line, so
	r_sum_sq *= r_sum_sq;	// dont recompute r1 + r2

	return alloc_bool( dcentre_sq - r_sum_sq);// <= (offset*offset) );
}

DEFINE_PRIM(nme_collision_pixel, 5);
DEFINE_PRIM(nme_collision_boundingbox, 3);
DEFINE_PRIM(nme_collision_boundingcircle, 3);

int __force_collision = 0;
