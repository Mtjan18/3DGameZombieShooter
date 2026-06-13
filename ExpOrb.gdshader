shader_type spatial;
render_mode unshaded; // Cocok untuk orb karena dia harus menyala terang seperti sumber energi

uniform vec3 base_color : source_color = vec3(0.0, 0.5, 1.0); // Warna dasar
uniform float pulse_speed = 3.0;

void fragment() {
	// Fresnel effect: Membaca sudut pandang kamera untuk membuat aura di pinggiran bola
	float fresnel = sqrt(1.0 - dot(NORMAL, VIEW));
	
	// Efek denyut ukuran aura
	float pulse = (sin(TIME * pulse_speed) + 1.0) / 2.0;
	
	ALBEDO = base_color;
	
	// Tembakkan warna dengan sangat terang
	EMISSION = base_color * (fresnel + pulse) * 2.5;
	
	// (Opsional) Jika materialmu mengaktifkan "Transparency: Alpha" di Inspector,
	// baris ini akan membuat bola sedikit transparan di tengah layaknya hantu/energi murni.
	ALPHA = fresnel * 1.5; 
}