import Image

basewidth = 188
img = Image.open('LostSeriesArtworks/artwork="The Tomorrow People"-1.jpg')
wpercent = (basewidth/float(img.size[0]))
print wpercent
hsize = int((float(img.size[1])*float(wpercent)))
print hsize
img = img.resize((188, 188), Image.ANTIALIAS)
quality_val = 100
img.save("LostSeriesArtworks/thumbnail-tp.jpg", "JPEG", quality=90)
