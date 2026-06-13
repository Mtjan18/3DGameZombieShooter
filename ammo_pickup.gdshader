shader_type spatial;
// HAPUS 'render_mode unshaded' agar peluru kembali berbentuk 3D dan bisa memantulkan cahaya!

// Parameter yang bisa diatur dari script (Kuning / Biru)
uniform vec3 base_color : source_color = vec3(1.0, 0.8, 0.0);
uniform float pulse_speed = 4.0; // Kecepatan kerlap-kerlip / denyut

void fragment() {
	// 1. MATERIAL DASAR: Bikin pelurunya mengkilap (Glossy/Metal)
	ALBEDO = base_color;
	METALLIC = 0.8;    // Semakin mendekati 1.0, semakin terlihat seperti besi
	ROUGHNESS = 0.15;  // Semakin mendekati 0.0, permukaannya semakin licin/memantul
	
	// 2. LOGIKA KERLAP-KERLIP MULUS
	// Menggunakan fungsi sin() dipadukan dengan TIME. 
	// Hasilnya akan berayun mulus dari 0.0 (mati) ke 1.0 (nyala penuh) tanpa patah-patah.
	float pulse = (sin(TIME * pulse_speed) + 1.0) / 2.0;
	
	// 3. EFEK BERSINAR (EMISSION)
	// Kita gabungkan warna dasar dengan sedikit warna putih agar saat menyala terang, ujungnya terlihat putih panas.
	vec3 glow_color = mix(base_color, vec3(1.0, 1.0, 1.0), 0.3);
	
	// Terapkan ke Emission dikalikan dengan kekuatan denyut (pulse)
	EMISSION = glow_color * pulse * 2.0; 
}