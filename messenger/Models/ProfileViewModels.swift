//
//  ProfileViewModels.swift
//  messenger
//
//  Created by TechnoMac6 on 15/02/22.
//

import Foundation

enum ProfileViewModelType{
    case info, logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}
