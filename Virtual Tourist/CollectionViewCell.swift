//
//  CollectionViewCell.swift
//
//  The cell for collection view. It displays the images for the album.
//  Created by Jeff Chiu on 12/20/2015.
//  Copyright (c) 2015 Jeff Chiu. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    //Cell will display the image and the activity indicator while loading.
    @IBOutlet var photo: UIImageView!
    @IBOutlet var indicator: UIActivityIndicatorView!
}

